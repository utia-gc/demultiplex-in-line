.PHONY: test_data
test_data: .cache/sentinels/sim_illumina_pe_fastqs.sentinel .cache/sentinels/create_sim_takara_3pde.sentinel
	@echo "Made test data files"

.cache/sentinels/sim_illumina_pe_fastqs.sentinel: src/bash/sim_illumina_pe_fastqs.sh
	@mkdir -p $(@D)
	@bash src/bash/sim_illumina_pe_fastqs.sh
	@touch $@

.cache/sentinels/create_sim_takara_3pde.sentinel: src/python/create_takara_3pde_fastqs.py src/bash/create_sim_takara_3pde.sh .cache/sentinels/sim_illumina_pe_fastqs.sentinel
	@mkdir -p $(@D)
	@bash src/bash/create_sim_takara_3pde.sh
	@touch $@
