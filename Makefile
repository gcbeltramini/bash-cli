.PHONY: install update test

install:
	@scripts/mycli_setup.sh

update:
	@mycli update

test:
	@scripts/tests/run_all_tests.sh
