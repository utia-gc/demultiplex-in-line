nextflow.enable.types = true

/** Create a sample metadata sheet for fqtk demux
 *
 * Given a multiplexed FASTQ prefix and a list of pairs of [sample level FASTQ prefix, inline barcode],
 * write a samplesheet for fqtk.
 *
 * @see https://docs.seqera.io/nextflow/tutorials/static-types-operators#collectfile
 */
process collect_demux_sample_metadata {
    tag "${demuxData.parentReadSet.readSetName}"

    label 'exec'

    // resource labels
    label 'lil_cpu'
    label 'lil_mem'
    label 'lil_time'
    // executor labels
    label 'local'

    input:
    demuxData: DemuxData

    output:
    record(
        parentReadSet: demuxData.parentReadSet,
        childrenMetadata: demuxData.childrenMetadata,
        sampleMetadata: file('*_fqtk-samplesheet.tsv')
    )

    exec:
    def path = task.workDir.resolve("${demuxData.parentReadSet.readSetName}_fqtk-samplesheet.tsv")
    path << "sample_id\tbarcode\n"
    demuxData.childrenMetadata.each { childMetadata ->
        path << "${childMetadata.childReadSetName}\t${childMetadata.inlineIndex}\n"
    }
}


record DemuxData {
    parentReadSet: ReadSet
    childrenMetadata: List<ChildMetadata>
}


record ReadSet {
    readSetName: String
    fastqR1: Path
    fastqR2: Path
}


record ChildMetadata {
    studyName: String
    childOutputName: String
    inlineIndex: String
    parentOutputName: String
    childReadSetName: String
}
