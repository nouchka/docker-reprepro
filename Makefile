DOCKER_IMAGE=reprepro
DOCKER_NAMESPACE=nouchka

.DEFAULT_GOAL := build

build:
	docker build -t $(DOCKER_NAMESPACE)/$(DOCKER_IMAGE) .

check:
	docker run --rm -i hadolint/hadolint < Dockerfile 2>/dev/null; true

run:
	docker-compose up -d

test: build check run
