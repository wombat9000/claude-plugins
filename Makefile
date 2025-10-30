.PHONY: validate-plugins

validate-plugins:
	@for plugin in plugins/*; do \
		echo "Validating $$plugin..."; \
		claude plugin validate "$$plugin"; \
	done
