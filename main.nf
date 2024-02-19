nextflow.enable.dsl=2

include { cutadapt_demultiplex } from './modules/cutadapt_demultiplex.nf'
include { Parse_Samplesheet    } from './subworkflows/parse_samplesheet.nf'

workflow {
    Channel
        .fromFilePairs(
            "${params.readsDir}/*_R{1,2}*.fastq.gz",
            // all planned demultiplexing requires PE reads, so requiring 2 files be found makes sense
            size: 2,
            checkIfExists: true
        )
        // change shape of read pairs channel
        // make flatter, i.e. [metadata, R1, R2]
        .map { metadata, reads ->
            [ metadata, reads[0], reads[1] ]
        }
        .set { ch_readPairs }
    ch_readPairs.dump(tag: "ch_readPairs")

    Parse_Samplesheet( params.samplesheet )
    ch_sampleDecodes = Parse_Samplesheet.out.sampleDecodes

    cutadapt_demultiplex(
        ch_readPairs,
        file("${projectDir}/assets/oligo_dt_in-line_primer_indexes.fasta")
    )
    cutadapt_demultiplex.out.demuxed.dump(tag: "Cutadapt demultiplexed reads")

    ch_demuxReads = cutadapt_demultiplex.out.demuxed

    // add the demultiplexed name as a grouping key for demultiplexed reads
    ch_demuxReads
        // get only the list of reads
        .map { meta, reads ->
            reads
        }
        // emit each read as a sole emission
        .flatten()
        // pull out the demultiplexed read name as a grouping key
        .map { demuxRead ->
            def demuxName = (demuxRead.getName() =~ /(.*)_S\d+_L\d{3}_R[12]_001.fastq.gz/)[0][1]
            [ demuxName, demuxRead ]
        }
        .set { ch_keyedDemuxReads }
    ch_keyedDemuxReads.dump(tag: 'Keyed demultiplexed reads')

    // add the demultiplexed name as a grouping key for sample name decode
    ch_sampleDecodes
        // pull out the demultiplexed read name as a grouping key
        .map { sampleDecode ->
            [ sampleDecode.demuxName, sampleDecode ]
        }
        .set { ch_keyedSampleDecodes }
    ch_keyedSampleDecodes.dump(tag: 'Keyed sample decodes')
}
