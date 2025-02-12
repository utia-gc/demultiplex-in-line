process cutadapt_demultiplex {
    tag "${sampleData.get('multiplexedSampleName')}"

    label 'cutadapt'

    label 'med_cpu'
    label 'med_mem'
    label 'med_time'

    input:
        tuple val(sampleData), path(reads1), path(reads2)
        path barcodes
        val errors

    output:
        tuple val(sampleData), path('IL*.fastq.gz'), emit: demuxed
        path('*.cutadapt.json'),                     emit: log

    script:
        String multiplexedSampleName = "${sampleData.get('multiplexedSampleName')}_S${sampleData.get('sampleNumber')}_L${sampleData.get('lane')}"
        String inlineIndexIDs = sampleData['demultiplexDecode'].keySet().toList().join(' ')

        """
        # construct array of in-line index IDs
        inline_index_ids=(${inlineIndexIDs})

        # make a fasta file of barcodes that are found in the array of in-line index IDs
        # skip header line
        tail -n +2 ${barcodes} \
        | while IFS=',' read -r inline_index_id illumina_id index_sequence
        do
            if [[ " \${inline_index_ids[@]} " =~ " \${inline_index_id} " ]]
            then
                echo -e ">\${inline_index_id}\\n\${index_sequence}" >> barcodes.fasta
            fi
        done
        

        # R1 and R2 have to be switched around because only matches to the first read are used to decide where a read should be written
        # however, reads are output in the "normal" orientation
        # i.e. because R2 is put for the output and R1 is used for the paired output, the R1s are output as forward reads and R2s are output as reverse reads
        cutadapt \\
            --no-indels \\
            --action none \\
            --compression-level 6 \\
            --cores ${task.cpus} \\
            --errors ${errors} \\
            -g ^file:barcodes.fasta \\
            --json ${multiplexedSampleName}.cutadapt.json \\
            --output {name}_${multiplexedSampleName}_R2_001.fastq.gz \\
            --paired-output {name}_${multiplexedSampleName}_R1_001.fastq.gz \\
            ${reads2} ${reads1}
        """
}
