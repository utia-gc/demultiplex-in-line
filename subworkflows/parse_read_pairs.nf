workflow Parse_Read_Pairs {
    take:
        readsSourceDir

    main:
        Channel
            .fromFilePairs(
                file(readsSourceDir).resolve("*_R{1,2}_001.fastq.gz"),
                // all planned demultiplexing requires PE reads, so requiring 2 files be found makes sense
                size: 2,
                checkIfExists: true
            )
            // change shape of read pairs channel
            // make flatter, i.e. [readPairName, R1, R2]
            .map { readPairName, reads ->
                def multiplexedReadNameMatcher = (readPairName =~ /(.*)_S(\d+)_L(\d{3})/)
                LinkedHashMap multiplexedNameData = [
                    'multiplexedSampleName': multiplexedReadNameMatcher[0][1],
                    'sampleNumber':          multiplexedReadNameMatcher[0][2],
                    'lane':                  multiplexedReadNameMatcher[0][3],
                ]

                [ multiplexedNameData, reads[0], reads[1] ]
            }
            .set { ch_readPairs }

    emit:
        readPairs = ch_readPairs
}
