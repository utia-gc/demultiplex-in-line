nextflow.enable.dsl=2

workflow {
    Channel
        .fromFilePairs(
            "${params.readsDir}/*_R{1,2}*.fastq.gz",
            // all planned demultiplexing requires PE reads, so requiring 2 files be found makes sense
            size: 2,
            checkIfExists: true
        )
        .set { ch_readPairs }
    ch_readPairs.dump(tag: "ch_readPairs")
}
