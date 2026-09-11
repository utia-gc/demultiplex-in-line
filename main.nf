nextflow.enable.types = true

include { collect_demux_sample_metadata } from './modules/fqtk/collect_demux_sample_metadata'
include { fqtk_demux } from './modules/fqtk/demux'
include { Parse_Samplesheet } from './subworkflows/parse_samplesheet.nf'

include { validateParameters } from 'plugin/nf-schema'

workflow {

    main:
    validateParameters()

    ch_demuxData = Parse_Samplesheet(params.samplesheet)

    ch_sampleMetadata = collect_demux_sample_metadata(ch_demuxData)

    ch_demuxOutput = fqtk_demux(
        ch_sampleMetadata,
        params.readStructures,
        params.cliArgsFqtkDemux,
    )
    ch_demuxOutput.view(tag: 'ch_demuxOutput')

    // the pipeline publishes child FASTQ files to subdirector(y)s of the output dir with the appropriate study name for each child FASTQ file
    // the fqtk_demux process spits out a list of the children read files
    // each FASTQ file must be associated with its study_name so that it can be published to the proper subdirectory
    // there is no need to keep R1 and R2 files paired for this
    // for each output channel from fqtk_demux, we must match each fastq file with its project name
    // this is done in preparation for publishing
    ch_childReadsWithStudyName = ch_demuxOutput.flatMap { demuxOutput ->
        // use the children metadata to build a map from child output name to study name
        def childOutputNameToStudyName = [:]
        demuxOutput.childrenMetadata.each { childMetadata ->
            childOutputNameToStudyName[childMetadata.childOutputName] = childMetadata.studyName
        }

        // find the child output name that matches each child read
        // use the map to populate a record with the child read and its associated study name
        def childReadsStudyNames = demuxOutput.childrenReads.collect { childReads ->
            // I can't think of a better way to do this than to find the child output name that matches the start of the child reads FASTQ file name
            def foundChildOutputName = childOutputNameToStudyName
                .keySet()
                .find { childOutputName ->
                    childReads.name.startsWith(childOutputName)
                }

            // look up the name of the associated study
            // if no associated study name, dump into unmatched
            def associatedStudyName = childOutputNameToStudyName[foundChildOutputName] ?: 'unmatched'
            return record(childReads: childReads, studyName: associatedStudyName)
        }

        return childReadsStudyNames
    }
    ch_childReadsWithStudyName.view()

    // the demux metrics file just needs a parent read set name to disambiguate what parent reads the metrics are associated with
    ch_demuxMetrics = ch_demuxOutput.map { demuxOutput ->
        return record(parentReadSetName: demuxOutput.parentReadSet.readSetName, metrics: demuxOutput.metrics)
    }

    publish:
    demuxFastqs = ch_childReadsWithStudyName
    demuxMetrics = ch_demuxMetrics
}

output {
    demuxFastqs {
        path { demuxFastq ->
            demuxFastq.childReads >> "${demuxFastq.studyName}/fastq/${demuxFastq.childReads.name.replace('.R1.fq.gz', '_R1_001.fastq.gz').replace('.R2.fq.gz', '_R2_001.fastq.gz')}"
        }
    }
    demuxMetrics {
        path { demuxMetric ->
            demuxMetric.metrics >> "qc/demux-metrics/${demuxMetric.parentReadSetName}_demux-metrics.txt"
        }
    }
}
