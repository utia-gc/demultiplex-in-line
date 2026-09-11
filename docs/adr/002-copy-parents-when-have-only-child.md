# Copy parent files when they have an only child

## Status

Accepted

## Context

When parent files only have one child, there are two options for how to generate those files: 1) demultiplex on the inline index like usual, or 2) treat all reads in the parent as if they belong to the child.

The first option makes sense as a highly principled approach.
However, practically why go through the trouble (e.g. computationally) of demutliplexing on a third index?
For sequencing projects that don't require additional multiplexing, we treat UDIs as sufficient.
Why would we treat these differently?
The only real argument I can see is that for RNA-seq specifically, there may be some slight bias in read quality that means filtering out reads with unmatched barcode samples in multiplexed samples but not in others makes some minor difference.
However, I don't think I buy that having a strong effect.

## Decision

Copy the parent files when they have an only child.
Don't bother with demultiplexing.

## Consequences

If a parent is multiplexed, all of its children MUST be explicitly listed in the samplesheet.

Requires additional logic and testing in the pipeline.
Unmatched reads and metrics files won't be produced for singleplexed parents.

On a positive, the pipeline will be faster.
