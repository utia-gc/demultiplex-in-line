workflow Parse_Samplesheet {
    take:
        samplesheet

    main:
        Channel
            .fromPath( samplesheet, checkIfExists: true )
            .splitCsv( header: true, sep: ',' )
            .map { row ->
                createSampleDecodesChannel(row)
            }
            .set { ch_sampleDecodes }
        ch_sampleDecodes.dump(tag: "ch_sampleDecodes")

    emit:
        sampleDecodes = ch_sampleDecodes
}


def createSampleDecodesChannel(LinkedHashMap decodeRow) {
    // make dummy file name by composing the i7 and i5 indexes (if available)
    def dummyName = decodeRow.i5Index ? "${decodeRow.i7Index}_${decodeRow.i5Index}" : "${decodeRow.i7Index}"
    decodeRow.put('dummyName', dummyName)
    // prepend in line index to the dummy name to generate the name of the demultiplexed sample
    def demuxName = "${decodeRow.inLineIndex}_${dummyName}"
    decodeRow.put('demuxName', demuxName)

    decodeRow
}
