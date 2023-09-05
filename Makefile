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
	$(VENV_NAME)/bin/pre-commit run --show-diff-on-failure --color=always --all-files

lint: $(VENV_NAME)
	$(VENV_NAME)/bin/cfn-lint

nag:
	cfn_nag $(path) --ignore-fatal

# Versioning and releases
.PHONY: version release
version: $(VENV_NAME)
	@$(VENV_NAME)/bin/bumpversion $(part)

release: # run on main branch only
	@TAG_VERSION=$(shell bumpversion --dry-run --list .bumpversion.cfg | grep current_version | sed s/'^.*='//); \
		git tag -a "v$${TAG_VERSION}" -m "" && git push origin "v$${TAG_VERSION}"

# Cleanup VirtualEnv
clean:
	rm -rf "$(VENV_NAME)"
	find . -iname "*.pyc" -delete
