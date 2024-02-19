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
}
