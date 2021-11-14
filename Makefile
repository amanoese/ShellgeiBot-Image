.PHENY: build prefetch

DOCKER_IMAGE_NAME := theoldmoon0602/shellgeibot
NODE_VERSION := $(shell curl -s https://nodejs.org/dist/index.json | jq -r '[.[]|select(.lts)][0].version')
BUILD_COMMAND := DOCKER_BUILDKIT=1 docker image build -t $(DOCKER_IMAGE_NAME) --build-arg NODE_VERSION=$(NODE_VERSION)
MULTI_ARCH_BUILD_COMMAND := DOCKER_BUILDKIT=1 docker buildx build -t $(DOCKER_IMAGE_NAME) --build-arg NODE_VERSION=$(NODE_VERSION)

build: prefetch buildlog revisionlog
	$(BUILD_COMMAND) .

build-ci: prefetch buildlog revisionlog
	$(BUILD_COMMAND) --progress=plain .

build-arm: prefetch-arm buildlog revisionlog
	$(MULTI_ARCH_BUILD_COMMAND) --platform linux/arm64 -f Dockerfile.arm64 .

prefetch:
	./prefetch_files.sh

prefetch-arm:
	./prefetch_files_arm64.sh

buildlog:
	./get_build_log.sh > ci_build.log

revisionlog:
	git log --pretty="format:%h %cd %s [%an]" --date=iso -n 20 > revision.log

test:
	docker container run \
		--rm \
		--net=none \
		--oom-kill-disable \
		--pids-limit=1024 \
		-v $(CURDIR):/root/src \
		$(DOCKER_IMAGE_NAME) \
		/bin/bash -c "bats /root/src/docker_image.bats"

clean:
	rm -f *.log
	rm -f prefetched/*.gz prefetched/*.zip
