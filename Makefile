SHELL := /bin/bash

.PHONY : help init test lint nag release clean
.DEFAULT: help

VENV_NAME ?= venv
PYTHON ?= $(VENV_NAME)/bin/python

help:
	@echo "help	get the full command list"
	@echo "init	create VirtualEnv and install libraries"
	@echo "test	run pre-commit checks"
	@echo "lint	GitHub actions cfn-lint test"
	@echo "nag	GitHub actions cfn-nag test"
	@echo "version	[part=major||minor||patch] bump version and tag release (make version part=patch)"
	@echo "release	push new tag to release branch"
	@echo "clean	delete VirtualEnv and installed libraries"

# Install VirtualEnv and dependencies
init: $(VENV_NAME) pre-commit

$(VENV_NAME): $(VENV_NAME)/bin/activate

$(VENV_NAME)/bin/activate: requirements.txt
	test -d $(VENV_NAME) || virtualenv -p python3 $(VENV_NAME)
	$(PYTHON) -m pip install -U pip
	$(PYTHON) -m pip install -Ur requirements.txt
	touch $(VENV_NAME)/bin/activate

pre-commit: $(VENV_NAME)
	$(VENV_NAME)/bin/pre-commit install

# Tests
test: $(VENV_NAME)
	$(VENV_NAME)/bin/pre-commit run --all-files

lint: $(VENV_NAME)
	$(VENV_NAME)/bin/cfn-lint code/solutions/**/*.yaml --ignore-templates code/solutions/policy-as-code-with-guard/example_bucket_tests.yaml

nag:
	cfn_nag_scan --input-path code/solutions --ignore-fatal

# Versioning and releases
version: $(VENV_NAME)
	@$(VENV_NAME)/bin/bumpversion $(part)

release:
	@TAG_VERSION=$(shell bumpversion --dry-run --list .bumpversion.cfg | grep current_version | sed s/'^.*='//); \
		git push origin "v$${TAG_VERSION}" && git push

# Cleanup VirtualEnv
clean:
	rm -rf "$(VENV_NAME)"
	find . -iname "*.pyc" -delete
