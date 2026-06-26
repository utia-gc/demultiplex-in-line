include { fqtk_demux } from './modules/fqtk/demux'
include { Parse_Samplesheet } from './subworkflows/parse_samplesheet.nf'

workflow {
    ch_fastqsAndFqtkSamplesheet = Parse_Samplesheet(params.samplesheet).fastqsAndFqtkSamplesheet
    ch_fastqsAndFqtkSamplesheet.view(tag: 'input')

    fqtk_demux(
        ch_fastqsAndFqtkSamplesheet,
        params.readStructures,
        params.cliArgsFqtkDemux,
    )
}
