SHELL := /bin/bash
QEMU_VERSION := v7.1.0

all:	build

version:
	@echo $(subst v,,$(QEMU_VERSION))

docker-tags:
	@echo latest
	@echo "$(subst v,,$(QEMU_VERSION))" | awk -F. '{print $$1" "$$1"."$$2" "$$1"."$$2"."$$3}'

build:
	docker build --build-arg=QEMU_RELEASE=$(QEMU_VERSION) --force-rm \
		-f Dockerfile -t madworx/qemu:$(shell make version) .
	for TAG in $(shell make docker-tags) ; do \
		docker tag madworx/qemu:$(shell make version) madworx/qemu:"$$TAG" ; \
	done

push:
	for TAG in $(shell make docker-tags) ; do \
		docker push madworx/qemu:"$$TAG" ; \
	done

reintegrate-qemu-release:
	rm -rf qemu.pristine qemu >/dev/null 2>&1 || true
	git clone --depth 1 --single-branch -b $(QEMU_VERSION) git://git.qemu-project.org/qemu.git qemu.pristine
	find ./patches -type f | while read PATCH ; do \
	  cp -a qemu.pristine qemu ; \
	  cd qemu ; \
	  git submodule update --init slirp ; \
	  echo "Patching $$(pwd) with ../$${PATCH}" ; \
	  patch -p1 -F3 <../$${PATCH} ; \
	  git diff --submodule=diff HEAD > ../$${PATCH}.tmp ; \
	  mv ../$${PATCH}.tmp ../$${PATCH} ; \
	  cd ../ ; \
	  rm -rf qemu  ; \
	done
	rm -rf qemu.pristine
