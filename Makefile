include tools/versions.mk

TOOLS := tools/bin
UV := uv run

.DEFAULT_GOAL := help

.PHONY: help
help:
	@echo ""
	@echo "Development Commands"
	@echo "===================="
	@echo ""
	@echo "Setup"
	@echo "-----"
	@echo "  make tools          Install development tools"
	@echo "  make reinstall      Reinstall development tools"
	@echo "  make doctor         Verify development environment"
	@echo ""
	@echo "Quality"
	@echo "-------"
	@echo "  make lint           Run all linters"
	@echo "  make lint-yaml      Lint YAML files"
	@echo "  make lint-actions   Lint GitHub Actions workflows"
	@echo "  make lint-docker    Lint Dockerfile"
	@echo "  make lint-security  Lint GitHub Actions security"
	@echo ""

.PHONY: tools
tools:
	@ACTIONLINT_VERSION=$(ACTIONLINT_VERSION) \
	HADOLINT_VERSION=$(HADOLINT_VERSION) \
	GOLANGCI_VERSION=$(GOLANGCI_VERSION) \
	./tools/install.sh
	@echo "✓ Development tools are ready."

.PHONY: reinstall
reinstall:
	@REINSTALL=1 $(MAKE) tools
	@echo "✓ Development tools reinstalled."

.PHONY: doctor
doctor:
	@test -x $(TOOLS)/actionlint || $(MAKE) --no-print-directory tools
	@printf "\n"
	@printf "Development Environment\n"
	@printf "=======================\n\n"
	@printf "%-18s %s\n" "Python" "$$(uv run python --version | awk '{print $$2}')"
	@printf "%-18s %s\n" "uv" "$$(uv --version | awk '{print $$2}')"
	@printf "%-18s %s\n" "Docker" "$$(docker version --format '{{.Client.Version}}')"
	@printf "%-18s %s\n" "actionlint" "$$($(TOOLS)/actionlint -version | head -1)"
	@printf "%-18s %s\n" "hadolint" "$$($(TOOLS)/hadolint --version | awk '{print $$NF}')"
	@printf "%-18s %s\n" "golangci-lint" "$$($(TOOLS)/golangci-lint version | awk '{print $$4}')"
	@printf "%-18s %s\n" "yamllint" "$$(uv run yamllint --version | awk '{print $$2}')"
	@printf "%-18s %s\n" "zizmor" "$$(uv run zizmor --version | awk '{print $$2}')"
	@echo

.PHONY: lint
lint: lint-yaml lint-actions lint-docker lint-security
	@echo
	@echo "✓ All lint checks passed."

.PHONY: lint-yaml
lint-yaml:
	@echo "==> YAML"
	@$(UV) yamllint .
	@echo "✓ YAML lint passed."

.PHONY: lint-actions
lint-actions:
	@echo
	@echo "==> GitHub Actions"
	@$(TOOLS)/actionlint
	@echo "✓ GitHub Actions lint passed."

.PHONY: lint-docker
lint-docker:
	@echo
	@echo "==> Docker"
	@$(TOOLS)/hadolint --failure-threshold warning Dockerfile
	@echo "✓ Docker lint passed."

.PHONY: lint-security
lint-security:
	@echo
	@echo "==> Security"
	@$(UV) zizmor .
	@echo "✓ Security lint passed."
