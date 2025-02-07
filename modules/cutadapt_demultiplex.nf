process cutadapt_demultiplex {
    tag "${metadata}"

    label 'cutadapt'

    label 'med_cpu'
    label 'med_mem'
    label 'med_time'

    input:
        tuple val(metadata), path(reads1), path(reads2)
        path barcodes
        val errors

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
            --compression-level 6 \\
            --cores ${task.cpus} \\
            --errors ${errors} \\
            -g ^file:${barcodes} \\
            --output {name}_${metadata}_R2_001.fastq.gz \\
            --paired-output {name}_${metadata}_R1_001.fastq.gz \\
            ${reads2} ${reads1} \\
            > ${metadata}_cutadapt-log.txt
        """
}
