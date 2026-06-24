# Use fqtk for demultiplexing

## Status

Proposed

## Context

As we have started using the FlexPrep technology from Twist Biosciences for creating libraries of target enrichment panels, we need to be able to demultiplex their libraries from multiplexed FASTQ files into sample-level FASTQs.
Twist officially recommends [fgbio DemuxFastqs](https://fulcrumgenomics.github.io/fgbio/tools/latest/DemuxFastqs.html) as the tool for demultiplexing.
The fgbio DemuxFastqs page states, "Please see https://github.com/fulcrumgenomics/fqtk for a faster and supported replacement."
In my testing, `fqtk demux` is about 15-20 times faster than `fgbio FastqDemux` and yields identical sequences.

We currently use cutadapt for demultiplexing based on in-line sequences.
However, none of the library preps we perform specifically recommend cutadapt -- it was primarily a convenient solution at the time.
While I haven't performed a direct comparison between cutadapt and fqtk, I think fqtk has several advantages.
The biggest is that its barcode specification system is very adaptable yet straightforward.
Patterns that may be difficult to specify to cutadapt are very easy to configure for fqtk.
fqtk also takes a straightforward sample sheet as input and names output files based on this samplesheet.
The major advantage here is less processing on the back end to apply the correct names to the demultiplexed FASTQ files, although fqtk requires this upfront so this may be somewhat of a wash.

One drawback for fqtk is that it does not have a MultiQC module as of MultiQC v1.35, so unlike cutadapt it is not quite as easy of a plug and play to summarize info from logs.
fqtk does output a metrics file, though, so it wouldn't be a major issue to add some sort of log summarization.

## Decision

## Consequences
