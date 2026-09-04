.PHONY: test_data
test_data: .cache/sentinels/sim_illumina_pe_fastqs.sentinel
	@echo "Made test data files"

.cache/sentinels/sim_illumina_pe_fastqs.sentinel: src/bash/sim_illumina_pe_fastqs.sh
	@mkdir -p $(@D)
	@bash src/bash/sim_illumina_pe_fastqs.sh
	@touch $@
