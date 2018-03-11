SHELL = bash
TRAVIS_BRANCH ?= $(shell git branch | grep \* | cut -d " " -f 2)
CI_BRANCH ?= $(TRAVIS_BRANCH)
TESTING_BUCKET := fowlmouthwings-com-testing-site
PROD_BUCKET := fowlmouthwings-com-prod-site
URL_MAP := sites-url-map
PROD_CDN_HOST := www.fowlmouthwings.com

.PHONY: build
build:  ## Build assets for a deploy
	@mkdir -p dist
	@cp -R assets dist
	@cp *.html dist

.PHONY: clean
clean:  ## Cleanup from a build
	@rm -rf dist

.PHONY: ci_setup
ci_setup:  ## Setup the CI system
	@mkdir -p $(HOME)/.gcloud
	@$(shell echo $(GCP_KEY_FILE) | base64 --decode > $(HOME)/keyfile.json)
	@gcloud auth activate-service-account --key-file=$(HOME)/keyfile.json
	@gcloud config set project $(GCP_PROJECT_ID)

.PHONY: deploy
deploy:  ## Deploy the project
	@if [ "$(CI_BRANCH)" == "master" ]; then \
		echo "Deploying to Testing Bucket"; \
		gsutil -m rsync -d -r dist gs://$(TESTING_BUCKET)/; \
	elif [ "$(CI_BRANCH)" == "release" ]; then \
		echo "Deploying to Prod Bucket"; \
		gsutil -m rsync -d -r dist gs://$(PROD_BUCKET)/; \
		gcloud compute url-maps invalidate-cdn-cache $(URL_MAP) --host $(PROD_CDN_HOST) --async --path "/*"; \
	else \
		echo "Not a deploy branch, no action performed"; \
	fi

.PHONY: release
release:  ## Create a release PR
	@hub pull-request -b release -h master -m Release
