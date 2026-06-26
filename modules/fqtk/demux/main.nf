process fqtk_demux {
    tag "${multiplexedFastqPrefix}"

    label 'fqtk'

    // at least 5 CPUs are required for fqtk demux to run, so go ahead and ensure that incase there is no 'huge_cpu' label set
    cpus 5
    label 'huge_cpu'

    input:
    tuple val(multiplexedFastqPrefix), path(multiplexedFastqR1), path(multiplexedFastqR2), path(fqtkSamplesheet)
    val readStructures
    val cliArgs

    output:
    tuple val(multiplexedFastqPrefix), path('*.fq.gz'), emit: demuxFastqs
    tuple val(multiplexedFastqPrefix), path('demux-metrics.txt'), emit: demuxMetrics

    script:
    """
    fqtk demux \\
        --inputs ${multiplexedFastqR1} ${multiplexedFastqR2} \\
        --read-structures ${readStructures} \\
        --sample-metadata ${fqtkSamplesheet} \\
        --output . \\
        --unmatched-prefix "unmatched_${multiplexedFastqPrefix}" \\
        --threads ${task.cpus} \\
        ${cliArgs}
    """
}
