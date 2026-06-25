include { Parse_Samplesheet } from './subworkflows/parse_samplesheet.nf'

workflow {
    Parse_Samplesheet(params.samplesheet)
}
