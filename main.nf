nextflow.enable.dsl=2

include { Parse_Samplesheet } from './subworkflows/parse_samplesheet.nf'

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


process cutadapt_demultiplex {
    label 'cutadapt'

    input:
        tuple val(metadata), path(reads1), path(reads2)
        path barcodes

    output:
        tuple val(metadata), path('*.fastq.gz'), emit: demuxed
        path('*_cutadapt-log.txt'), emit: log

    script:
        """
        # R1 and R2 have to be switched around because only matches to the first read are used to decide where a read should be written
        # however, reads are output in the "normal" orientation
        # i.e. because R2 is put for the output and R1 is used for the paired output, the R1s are output as forward reads and R2s are output as reverse reads
        cutadapt \\
            --no-indels \\
            --action none \\
            -g ^file:${barcodes} \\
            --output {name}_${metadata}_R2.fastq.gz \\
            --paired-output {name}_${metadata}_R1.fastq.gz \\
            ${reads2} ${reads1} \\
            > ${metadata}_cutadapt-log.txt
        """
}
