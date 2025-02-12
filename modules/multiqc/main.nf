process multiqc {
    tag "${fileName}"
    
    label 'multiqc'

    label 'def_cpu'
    label 'def_mem'
    label 'lil_time'

    publishDir(
        path: "${params.readsDestinationBaseDir}",
        mode: 'copy'
    )

    input:
        path('*')
        path config
        val fileName

    output:
        path "${fileName}.html",   hidden: true, emit: report
        path "${fileName}_data/*", hidden: true, emit: data

    script:
        """
        multiqc \
            --filename ${fileName} \
            --config ${config} \
            .
        """
}
