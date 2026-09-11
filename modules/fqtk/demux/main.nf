nextflow.enable.types = true

include { ReadSet; ChildMetadata } from '../../../modules/fqtk/collect_demux_sample_metadata'

/** Run fqtk demux
 * @see https://github.com/fulcrumgenomics/fqtk#fqtk-demux
 */
process fqtk_demux {
    tag "${parentReadSet.readSetName}"

    label 'fqtk'

    // at least 5 CPUs are required for fqtk demux to run, so go ahead and ensure that incase there is no 'huge_cpu' label set
    cpus 5
    label 'huge_cpu'

    input:
    record(
        parentReadSet: ReadSet,
        childrenMetadata: List<ChildMetadata>,
        sampleMetadata: Path
    )
    readStructures: String
    cliArgs: String

    output:
    record(
        parentReadSet: parentReadSet,
        childReads: files('*.fq.gz'),
        metrics: file('demux-metrics.txt', optional: true)
    )

    script:
    """
    fqtk demux \\
        --inputs ${parentReadSet.fastqR1} ${parentReadSet.fastqR2} \\
        --read-structures ${readStructures} \\
        --sample-metadata ${sampleMetadata} \\
        --output . \\
        --unmatched-prefix "unmatched_${parentReadSet.readSetName}" \\
        --threads ${task.cpus} \\
        ${cliArgs}
    """
}
