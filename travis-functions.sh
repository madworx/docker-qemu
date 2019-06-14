#!/bin/bash

set -eE
set -o pipefail

# Travis CI support functions

function ensure_autoupgrade_branch() {
    git remote remove origin
    git remote add origin https://${GH_TOKEN}@github.com/madworx/docker-qemu
    git checkout autoupgrade || git checkout -b autoupgrade
    echo "Ensured autoupgrade branch. Now attempting to do a fast-forward merge against ${TRAVIS_BRANCH}."
    if git merge --ff-only "${TRAVIS_BRANCH}" ; then
        git push --set-upstream origin autoupgrade
    else
        echo "Unable to perform a ff-merge against ${TRAVIS_BRANCH}. Aborting attempt."
    fi
}

function set_makefile_qemu_version() {
    CURRENT_QEMU="$1"
    LATEST_QEMU="$2"
    echo "Newer version (${LATEST_QEMU}) found instead of current (${CURRENT_QEMU}). Patching Makefile"
    sed -e "s#^\\(QEMU_VERSION :=\\).*#\\1 ${LATEST_QEMU}#" -i Makefile
}

function create_autobuild_branch() {
    LATEST_QEMU="$1"
    BRANCH_NAME="autobuild-${LATEST_QEMU}"
    echo "Re-integration worked. Deleting possible old autobuild branch for this version and commit new one."
    git remote remove origin
    git remote add origin https://${GH_TOKEN}@github.com/madworx/docker-qemu
    git branch -D "${BRANCH_NAME}" || true
    git push origin :"${BRANCH_NAME}" || true
    git checkout -b "${BRANCH_NAME}"
    git commit -a -m "Reintegration against ${LATEST_QEMU} worked."
    git remote -v
    git push -u origin "${BRANCH_NAME}"
}
