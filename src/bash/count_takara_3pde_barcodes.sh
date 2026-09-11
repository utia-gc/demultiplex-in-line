#!/usr/bin/env bash
#
# Count the number of the barcodes in each of the Takara 3' DE simulated files.


set -euo pipefail

r2_fastqs=(tests/data/reads/raw/takara_3de*_R2_001.fastq.gz)
for r2_fastq in "${r2_fastqs[@]}"; do
	echo "${r2_fastq}"
	zcat "${r2_fastq}" |
		awk 'NR % 4 ==2 {print substr($0, 1, 6)} ' - |
		sort - |
		uniq -c
done
