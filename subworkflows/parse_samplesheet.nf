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
    def dummyName = "${decodeRow.i7Index}_${decodeRow.i5Index}"
    decodeRow.put('dummyName', dummyName)
    def demuxName = "${decodeRow.inLineIndex}_${dummyName}"
    decodeRow.put('demuxName', demuxName)

    decodeRow
}
