#!/usr/bin/env bash
#
# Add Takara 3'DE style barcodes to simulated reads


set -euo pipefail

# set parameters for simulating reads
readonly fastq_r1_paths=(tests/data/reads/raw/iss_generate_seed*_R1_001.fastq.gz)
readonly sequencing_output_prefix="iss_generate_seed"
readonly output_dir="tests/data/reads/raw"

# make sure files have output directory to land in
mkdir -p "${output_dir}"

# generate simulated reads
for i in "${!fastq_r1_paths[@]}"; do
	fastq_r1_path="${fastq_r1_paths[i]}"
	echo "R1 FASTQ path: '${fastq_r1_path}'"
	fastq_r2_path="${fastq_r1_path/_R1_001.fastq.gz/_R2_001.fastq.gz}"
	echo "R2 FASTQ path: '${fastq_r2_path}'"

	fastq_stem="$(basename ${fastq_r1_path/_R1_001.fastq.gz/})"
	output_name="${output_dir}/${fastq_stem/iss_generate/takara_3de-$i}"
	echo "${output_name}"

	uv run --script src/python/create_takara_3pde_fastqs.py \
		--seed "${i}" \
		"${fastq_r1_path}" \
		"${fastq_r2_path}" \
		"${output_name}"
done
