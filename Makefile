SHELL := /bin/bash

.PHONY : help init test lint nag release clean sync
.DEFAULT: help

VENV_NAME ?= .venv
PYTHON ?= $(VENV_NAME)/bin/python
PUBLIC_REPO ?= ../cfn-workshop-github

help:
	@echo "help	get the full command list"
	@echo "init	create VirtualEnv with uv and install libraries"
	@echo "test	run pre-commit checks"
	@echo "lint	GitHub actions cfn-lint test"
	@echo "nag	GitHub actions cfn-nag test"
	@echo "sync	sync files to public GitHub repo (excludes content/, static/, contentspec.yaml, docs/)"
	@echo "version	[part=major||minor||patch] bump version and tag release (make version part=patch)"
	@echo "release	push new tag to release branch"
	@echo "clean	delete VirtualEnv and installed libraries"

# Install VirtualEnv and dependencies
init: $(VENV_NAME) pre-commit

$(VENV_NAME): $(VENV_NAME)/bin/activate

$(VENV_NAME)/bin/activate: pyproject.toml .python-version
	uv venv --python-preference only-managed
	uv pip install -r pyproject.toml
	touch $(VENV_NAME)/bin/activate

pre-commit: $(VENV_NAME)
	GIT_CONFIG=/dev/null $(VENV_NAME)/bin/pre-commit install

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

# Sync to public GitHub repo
sync:
	@echo "Syncing to public GitHub repo..."
	@rsync -av --delete \
		--exclude='.git/' \
		--exclude='.venv/' \
		--exclude='content/' \
		--exclude='static/' \
		--exclude='contentspec.yaml' \
		--exclude='docs/' \
		--exclude='.gitignore' \
		--exclude='*.pyc' \
		--exclude='__pycache__/' \
		./ $(PUBLIC_REPO)/
	@echo "Sync complete!"
