nextflow.enable.types = true

include { samplesheetToList } from 'plugin/nf-schema'

workflow Parse_Samplesheet {
    take:
    samplesheet: Path

    main:
    ch_demuxData = channel.fromList(
            samplesheetToList(samplesheet, "${projectDir}/assets/schema_samplesheet.json")
        )
        .map { studyName, childOutputName, inlineIndex, parentOutputName, parentFastqPathR1, parentFastqPathR2 ->
            // infer the name of the parent read set by stripping extensions and common prefixes and suffixes from the name
            def parentReadSetName = parentFastqPathR1.simpleName.replace("_R1_001", "")
            // set the name for the child read set
            // replace the parent output name with the child output name in the parent read set name
            def childReadSetName = parentReadSetName.replace(parentOutputName, childOutputName)

            // build data structures to track downstream information
            def parentFastqs = record(
                readSetName: parentReadSetName,
                fastqR1: parentFastqPathR1,
                fastqR2: parentFastqPathR2,
            )
            def childMetadata = record(
                studyName: studyName,
                childOutputName: childOutputName,
                inlineIndex: inlineIndex,
                parentOutputName: parentOutputName,
                childReadSetName: childReadSetName,
            )

            return [parentFastqs, childMetadata]
        }
        .groupBy()
        .map { parentFastqs, childrenMetadata ->
            def demuxData = record(
                parentReadSet: parentFastqs,
                childrenMetadata: childrenMetadata.toSorted(),
            )

            return demuxData
        }
    ch_demuxData.view(tag: 'ch_demuxData')

    emit:
    demuxData: Channel<Record> = ch_demuxData
}
