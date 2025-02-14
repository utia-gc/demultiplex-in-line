include { multiqc } from '../../modules/multiqc'


workflow QC {
    take:
        demuxLogs

    main:
        ch_percentUnknown = demuxLogs
            .map { demuxLog ->
                // construct sample name from demultiplex log file name
                String multiplexedSampleName = demuxLog.getName().replaceFirst(/\.cutadapt\.json/, '')

                // parse demux log json file and compute percent unknown read counts
                LinkedHashMap readCounts = new groovy.json.JsonSlurper().parseText(demuxLog.text)['read_counts']

                log.info """Sample: ${multiplexedSampleName} -- Input n reads: ${readCounts['input']} -- R1 w/ adapter: ${readCounts['read1_with_adapter']}"""

                Float percentUnknown = 100 * (readCounts['input'] - readCounts['read1_with_adapter']) / readCounts['input']
                log.info """Sample: ${multiplexedSampleName} -- Percent unknown: ${percentUnknown}"""

                return [ multiplexedSampleName, percentUnknown ]
            }
            .collectFile(name: 'percent-unknown.csv', newLine: true, seed: 'sample,percent_unknown', sort: true) { multiplexedSampleName, percentUnknown ->
                "${multiplexedSampleName},${percentUnknown}"
            }
            .dump(pretty: true, tag: 'ch_percentUnknown')

        ch_multiqc = Channel.empty()
            .concat(demuxLogs)
            .concat(ch_percentUnknown)
            .collect(
                sort: { a, b ->
                    a.name <=> b.name
                }
            )
            .dump(pretty: true, tag: 'ch_multiqc')

        multiqc(
            ch_multiqc,
            file("${projectDir}/assets/multiqc_config.yaml"),
            'demultiplex'
        )
}
