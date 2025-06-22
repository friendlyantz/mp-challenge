.DEFAULT_GOAL := usage

# user and repo
USER        = $$(whoami)
CURRENT_DIR = $(notdir $(shell pwd))

# terminal colours
RED     = \033[0;31m
GREEN   = \033[0;32m
YELLOW  = \033[0;33m
NC      = \033[0m
# versions
APP_REVISION    = $(shell git rev-parse HEAD)

.PHONY: install
install:
	bundle install

.PHONY: run
run:
	./bin/run

.PHONY: lint
lint:
	bundle exec standardrb --fix

.PHONY: test
test:
	bundle exec rspec

.PHONY: usage
usage:
	@echo
	@echo "Hi ${GREEN}${USER}!${NC} Welcome to ${RED}${CURRENT_DIR}${NC}"
	@echo
	@echo "Getting started"
	@echo
	@echo "${YELLOW}make install${NC}                  install dependencies"
	@echo "${YELLOW}make test${NC}                     test app"
	@echo
	@echo "${YELLOW}make run${NC}                      run server"
	@echo
	@echo "${YELLOW}make lint${NC}                     lint app"
	@echo