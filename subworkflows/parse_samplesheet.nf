workflow Parse_Samplesheet {
    take:
        samplesheet

    main:
        Channel
            .fromPath( samplesheet, checkIfExists: true )
            .splitCsv( header: true, sep: ',' )
            /*
             * Create a single massive map for all the decode samples
             *
             * This map has a single entry for each multiplexed sample name.
             * Each multiplexed sample name has a map of in-line ID to demultiplexed sample name and project.
             */
            .collect()
            .map {
                LinkedHashMap sampleDecode = [:]
                it.each{ row ->
                    // put multiplexed sample name in sample decode with empty map if the name isn't already
                    if (sampleDecode.get(row['multiplexedSampleName']) == null) {
                        sampleDecode.put(row['multiplexedSampleName'], [:])
                    }
                    // add demultiplexed sample name and project for each in-line index
                    sampleDecode[row['multiplexedSampleName']].put(
                        row['inLineIndex'],
                        [
                            'demultiplexedSampleName': row['demultiplexedSampleName'],
                            'project':                 row['project'],
                        ]
                    )
                }

                return sampleDecode
            }
            .set { ch_sampleDecodes }

    emit:
        sampleDecodes = ch_sampleDecodes
}
