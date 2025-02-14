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
                Float percentUnknown = computePercentUnknown(readCounts)

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


/**
* Computes the percentage of reads that did not contain the expected adapter sequences.
*
* @param readCounts LinkedHashMap containing read count data. 
*        This is most easily created by grabbing the 'read_counts' section of the cutadapt json log file.
*        Keys:
*            - 'input': Integer, total number of input reads
*            - 'read1_with_adapter': Integer, number of reads containing the adapter sequence
* @return Float percentage (0-100) of reads without adapters
* @throws NullPointerException if required keys are missing from readCounts
* @throws ArithmeticException if input reads count is 0
*/
Float computePercentUnknown(LinkedHashMap readCounts) {
    Integer nTotalReads = readCounts['input']
    Integer nDemultiplexedReads = readCounts['read1_with_adapter']
    Integer nUnknownReads = nTotalReads - nDemultiplexedReads
    Float proportionUnknown = nUnknownReads / nTotalReads
    Float percentUnknown = 100 * proportionUnknown

    return percentUnknown
}
