.PHONY: test_data
test_data: tests/data/samplesheets/takara_3pde_samplesheet.csv tests/data/samplesheets/takara_3pde_samplesheet_single-row.csv tests/data/samplesheets/takara_3pde_samplesheet_single-sample.csv
	@echo "Made test data files"

.cache/sentinels/sim_illumina_pe_fastqs.sentinel: src/bash/sim_illumina_pe_fastqs.sh
	@mkdir -p $(@D)
	@bash src/bash/sim_illumina_pe_fastqs.sh
	@touch $@

.cache/sentinels/create_sim_takara_3pde.sentinel: src/python/create_takara_3pde_fastqs.py src/bash/create_sim_takara_3pde.sh .cache/sentinels/sim_illumina_pe_fastqs.sentinel
	@mkdir -p $(@D)
	@bash src/bash/create_sim_takara_3pde.sh
	@touch $@

tests/data/samplesheets/takara_3pde_samplesheet.csv: src/bash/build_takara_3pde_samplesheet.sh .cache/sentinels/create_sim_takara_3pde.sentinel
	@mkdir -p $(@D)
	@bash src/bash/build_takara_3pde_samplesheet.sh

tests/data/samplesheets/takara_3pde_samplesheet_single-row.csv: tests/data/samplesheets/takara_3pde_samplesheet.csv
	@head -n 2 tests/data/samplesheets/takara_3pde_samplesheet.csv > $@

tests/data/samplesheets/takara_3pde_samplesheet_single-sample.csv: tests/data/samplesheets/takara_3pde_samplesheet.csv
	@head -n 1 tests/data/samplesheets/takara_3pde_samplesheet.csv > $@
	@grep ',baz1,' tests/data/samplesheets/takara_3pde_samplesheet.csv >> $@
