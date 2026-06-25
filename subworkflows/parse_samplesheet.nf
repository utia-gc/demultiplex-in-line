include { samplesheetToList } from 'plugin/nf-schema'

workflow Parse_Samplesheet {
    take:
    samplesheet

    main:
    ch_samplesheetComposite = channel.fromList(
            samplesheetToList(samplesheet, "${projectDir}/assets/schema_samplesheet.json")
        )
        .map { sampleFastqPrefix, inline, multiplexedFastqFilePathR1, multiplexedFastqFilePathR2 ->
            def fastqR1Prefix = multiplexedFastqFilePathR1.name.replaceFirst(/_R1_001\.fastq\.gz/, "")
            def fastqR2Prefix = multiplexedFastqFilePathR2.name.replaceFirst(/_R2_001\.fastq\.gz/, "")

            if (fastqR1Prefix != fastqR2Prefix) {
                error("R1 (${multiplexedFastqFilePathR1}) and R2(${multiplexedFastqFilePathR2}) files have different prefixes. Check that files are named correctly and properly paired.")
            }

            return [fastqR1Prefix, multiplexedFastqFilePathR1, multiplexedFastqFilePathR2, sampleFastqPrefix, inline]
        }

    ch_multiplexedFastqs = ch_samplesheetComposite
        .map { multiplexedFastqPrefix, multiplexedFastqFilePathR1, multiplexedFastqFilePathR2, _sampleFastqPrefix, _inline ->
            return [multiplexedFastqPrefix, [multiplexedFastqFilePathR1, multiplexedFastqFilePathR2]]
        }
        .groupBy()
        .map { multiplexedFastqPrefix, multiplexedFastqFilePaths ->
            return [multiplexedFastqPrefix, multiplexedFastqFilePaths.head()]
        }
    ch_multiplexedFastqs.view()

    ch_sampleInfo = ch_samplesheetComposite
        .map { multiplexedFastqPrefix, _multiplexedFastqFilePathR1, _multiplexedFastqFilePathR2, sampleFastqPrefix, inline ->
            return [multiplexedFastqPrefix, [sampleFastqPrefix, inline]]
        }
        .groupBy()
        .map { multiplexedFastqPrefix, sampleInfo ->
            // don't really care about sort order, just need it to be deterministic
            return [multiplexedFastqPrefix, sampleInfo.toSorted()]
        }
    ch_sampleInfo.view()

    ch_fqtkSamplesheet = collect_fqtk_samplesheet(ch_sampleInfo)
    ch_fqtkSamplesheet.view { multiplexedFastqPrefix, fqtkSamplesheet -> println("${multiplexedFastqPrefix}: ${fqtkSamplesheet.name}\n${fqtkSamplesheet.text}") }

    ch_fastqsAndFqtkSamplesheet = ch_multiplexedFastqs
        .join(ch_fqtkSamplesheet, by: 0)
        .map { multiplexedFastqPrefix, multiplexedFastqs, fqtkSamplesheet ->
            return [multiplexedFastqPrefix, multiplexedFastqs[0], multiplexedFastqs[1], fqtkSamplesheet]
        }
        .view()

    emit:
    fastqsAndFqtkSamplesheet = ch_fastqsAndFqtkSamplesheet
}


/** Create a samplesheet for fqtk demux
 *
 * Given a multiplexed FASTQ prefix and a list of pairs of [sample level FASTQ prefix, inline barcode],
 * write a samplesheet for fqtk.
 *
 * @see https://docs.seqera.io/nextflow/tutorials/static-types-operators#collectfile
 */
process collect_fqtk_samplesheet {
    input:
    tuple val(multiplexedFastqPrefix), val(sampleInfo)

    output:
    tuple val(multiplexedFastqPrefix), path("${multiplexedFastqPrefix}_fqtk-samplesheet.tsv")

    exec:
    def path = task.workDir.resolve("${multiplexedFastqPrefix}_fqtk-samplesheet.tsv")
    path << "sample_id\tbarcode\n"
    sampleInfo.each { sampleFastqPrefix, inlineBarcode ->
        path << "${sampleFastqPrefix}\t${inlineBarcode}\n"
    }
}
