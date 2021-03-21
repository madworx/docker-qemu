SHELL := /bin/bash
QEMU_VERSION := v5.2.0

all:	build

version:
	@QEMU_VERSION=$(QEMU_VERSION) ; echo $${QEMU_VERSION:1}

docker-tags:
	@QEMU_VERSION=$(QEMU_VERSION) ; \
	QEMU_VERSION=$${QEMU_VERSION:1} ; \
	echo "$${QEMU_VERSION} " ; \
	[[ "$${QEMU_VERSION}" =~ rc ]] \
		|| echo "$${QEMU_VERSION%.*}" "$${QEMU_VERSION%%.*}"

build:
	docker build --build-arg=QEMU_RELEASE=$(QEMU_VERSION) --force-rm \
		-f Dockerfile -t madworx/qemu:$(QEMU_VERSION) .
	docker tag madworx/qemu:$(QEMU_VERSION) madworx/qemu:latest

push:
	docker push madworx/qemu:latest
	docker push madworx/qemu:$(QEMU_VERSION)

reintegrate-qemu-release:
	rm -rf qemu.pristine qemu >/dev/null 2>&1 || true
	git clone --depth 1 --single-branch -b $(QEMU_VERSION) git://git.qemu-project.org/qemu.git qemu.pristine
	find ./patches -type f | while read PATCH ; do \
	  cp -a qemu.pristine qemu ; \
	  cd qemu ; \
	  echo "Patching $$(pwd) with ../$${PATCH}" ; \
	  patch -p1 -F3 <../$${PATCH} ; \
	  git diff HEAD > ../$${PATCH}.tmp ; \
	  mv ../$${PATCH}.tmp ../$${PATCH} ; \
	  cd ../ ; \
	  rm -rf qemu  ; \
	done
	rm -rf qemu.pristine
