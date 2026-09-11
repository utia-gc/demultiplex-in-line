#!/usr/bin/env bash
# Build the test samplesheet for the Takara 3'DE test data.


set -euo pipefail

readonly output_samplesheet_path="tests/data/samplesheets/takara_3pde_samplesheet.csv"

# setup parents data
readonly fastq_r1_paths=(tests/data/reads/raw/takara*_R1_001.fastq.gz)
read -r -d '' parents < <(
	for fastq_r1_path in "${fastq_r1_paths[@]}"; do
		fastq_r2_path="${fastq_r1_path/_R1_001.fastq.gz/_R2_001.fastq.gz}"

		tmp="${fastq_r1_path##*/}"
		parent_output_name="${tmp/_S*_L00*_R1_001.fastq.gz/}"
		
		echo "${parent_output_name},${fastq_r1_path},${fastq_r2_path}"
	done
) || true

# preview parents file
echo "Preview parents:"
cat <<< "${parents}"

# setup map from child to parents
read -r -d '' children_map << 'EOF' || true
fizz,foo1,CTAGCT,takara_3de-0_seed-11
fizz,foo1,CTAGCT,takara_3de-1_seed-12
fizz,foo2,CGATGT,takara_3de-0_seed-11
fizz,foo2,CGATGT,takara_3de-1_seed-12
fizz,foo3,TGACCA,takara_3de-0_seed-11
fizz,foo3,TCACCA,takara_3de-1_seed-12
fizz,bar1,CTAGCT,takara_3de-2_seed-21
fizz,bar1,CTAGCT,takara_3de-3_seed-22
fizz,bar2,CGATGT,takara_3de-2_seed-21
fizz,bar2,CGATGT,takara_3de-3_seed-22
fizz,bar3,TGACCA,takara_3de-2_seed-21
fizz,bar3,TCACCA,takara_3de-3_seed-22
buzz,baz1,CTAGCT,takara_3de-4_seed-31
buzz,baz1,CTAGCT,takara_3de-5_seed-32
buzz,baz2,CGATGT,takara_3de-4_seed-31
buzz,baz2,CGATGT,takara_3de-5_seed-32
buzz,baz3,TGACCA,takara_3de-4_seed-31
buzz,baz3,TCACCA,takara_3de-5_seed-32
EOF

# preview parents file
echo "Preview children map:"
cat <<< "${children_map}"

mkdir -p "${output_samplesheet_path%/*}"

# join 'em!
join -t ',' -1 1 -2 4 \
	<(sort -t ',' -k 1 <<< "${parents}") \
	<(sort -t ',' -k 4 <<< "${children_map}") |
	awk '
		BEGIN { FS = ","; OFS = ","; print "study_name,child_output_name,inline_index,parent_output_name,parent_fastq_path_r1,parent_fastq_path_r2" }
		{ print $4, $5, $6, $1, $2, $3 }
	' - > "${output_samplesheet_path}"
