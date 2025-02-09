.PHONY: install update test

install:
	@scripts/mycli_setup.sh

update:
	@mycli update

test:
	@if [[ -z "$(type)" || "$(type)" == "all" ]]; then scripts/tests/run_all_tests.sh; \
	elif [[ "$(type)" == "docs" ]]; then scripts/tests/test_docs.sh; \
	elif [[ "$(type)" == "helpers" ]]; then scripts/tests/test_helper_files.sh; \
	elif [[ "$(type)" == "python" ]]; then scripts/tests/test_python.sh; \
	elif [[ "$(type)" == "shell-linter" ]]; then scripts/tests/test_shell_linter.sh; \
	elif [[ "$(type)" == "shell-unit" ]]; then scripts/tests/test_shell_unit_tests.sh; \
	elif [[ "$(type)" == "valid-file" ]]; then scripts/tests/test_valid_file.sh; \
	elif [[ "$(type)" == "valid-shell-file" ]]; then scripts/tests/test_valid_shell_file.sh; \
	else echo "[ERROR] Invalid type = '$(type)'"; \
	fi
