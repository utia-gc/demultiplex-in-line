#!/usr/bin/env bash
#
# Simulate Illumina style paired end reads in FASTQ format.


set -euo pipefail

# download fasta to use as reference
# to a temporary file that is deleted on exit
temp_reference=$(mktemp "${TMPDIR:-/tmp}/XXXXXXXX.fna.gz")
trap 'rm -f "${temp_reference}" "${temp_reference%.gz}"' EXIT INT TERM HUP

readonly reference_url="https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/002/263/795/GCF_002263795.3_ARS-UCD2.0/GCF_002263795.3_ARS-UCD2.0_assembly_structure/Primary_Assembly/assembled_chromosomes/FASTA/chr27.fna.gz"

wget --no-verbose --output-document="${temp_reference}" -- "${reference_url}"

# read simulation software can't take GZIPped input reference
gunzip "${temp_reference}"

# set parameters for simulating reads
readonly sample_numbers=(1 2 3)
readonly lane_numbers=(1 2)
readonly sequencing_output_prefix="iss_generate_seed"
readonly output_dir="tests/data/reads/raw"
readonly n_reads="100000"

# make sure files have output directory to land in
mkdir -p "${output_dir}"

# generate simulated reads
for sample_number in "${sample_numbers[@]}"; do
	for lane_number in "${lane_numbers[@]}"; do
		# create a unique prefix for the output file names
		output_name="${output_dir}/${sequencing_output_prefix}-${sample_number}${lane_number}_S${sample_number}_L00${lane_number}"

		# simulate the 
		apptainer exec docker://quay.io/biocontainers/insilicoseq:2.0.1--pyh7cba7a3_0 \
			iss generate \
			--seed "${sample_number}${lane_number}" \
			--cpus 1 \
			--genomes "${temp_reference%.gz}" \
			--n_reads "${n_reads}" \
			--model NovaSeq \
			--output "${output_dir}/out" \
			--compress

		mv "${output_dir}/out_R1.fastq.gz" "${output_name}_R1_001.fastq.gz"
		mv "${output_dir}/out_R2.fastq.gz" "${output_name}_R2_001.fastq.gz"

		# cleanup
		rm "${output_dir}/out_abundance.txt" "${output_dir}/out.iss.tmp.0.vcf"
	done
done

exit 0
