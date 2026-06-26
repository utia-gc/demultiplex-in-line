include { fqtk_demux } from './modules/fqtk/demux'
include { Parse_Samplesheet } from './subworkflows/parse_samplesheet.nf'

workflow {

    main:
    ch_fastqsAndFqtkSamplesheet = Parse_Samplesheet(params.samplesheet).fastqsAndFqtkSamplesheet
    ch_fastqsAndFqtkSamplesheet.view(tag: 'input')

    fqtk_demux(
        ch_fastqsAndFqtkSamplesheet,
        params.readStructures,
        params.cliArgsFqtkDemux,
    )
    ch_demuxFastqs = fqtk_demux.out.demuxFastqs.flatMap { multiplexedFastqPrefix, demuxFastqsR1, demuxFastqsR2 ->
        demuxFastqsR1
            .getIndices()
            .collect { i -> tuple(multiplexedFastqPrefix, demuxFastqsR1[i], demuxFastqsR2[i]) }
    }
    ch_demuxMetrics = fqtk_demux.out.demuxMetrics

    publish:
    demuxFastqs = ch_demuxFastqs
    demuxMetrics = ch_demuxMetrics
}

output {
    demuxFastqs {
        path { _multiplexedFastqPrefix, demuxFastqsR1, demuxFastqsR2 ->
            demuxFastqsR1 >> "fastq/${demuxFastqsR1.name.replace('.R1.fq.gz', '_R1.fastq.gz')}"
            demuxFastqsR2 >> "fastq/${demuxFastqsR2.name.replace('.R2.fq.gz', '_R2.fastq.gz')}"
        }
    }
    demuxMetrics {
        path { multiplexedFastqPrefix, demuxMetrics ->
            demuxMetrics >> "qc/demux-metrics/${multiplexedFastqPrefix}_demux-metrics.txt"
        }
    }
}
