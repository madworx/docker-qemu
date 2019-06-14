#!/bin/bash

set -eE
set -o pipefail

# Travis CI support functions

function ensure_autoupgrade_branch() {
    git remote remove origin
    git remote add origin https://${GH_TOKEN}@github.com/madworx/docker-qemu
    git checkout autoupgrade || git checkout -b autoupgrade
    
    echo "Ensured autoupgrade branch. Checking if we can do fast-forward merge against ${TRAVIS_BRANCH}."
    if ! git merge --ff-only "${TRAVIS_BRANCH}" ; then
        # PR might not exist here.
        ERRMSG="Unable to perform a ff-merge against ${TRAVIS_BRANCH}. Aborting attempt."
        comment_on_pr "${ERRMSG}" || echo "${ERRMSG}. Also, no PR exists towards the autoupgrade branch so not logging status there."
        exit 1
    fi
}

function merge_autobuild_against_autoupgrade() {
    git checkout autoupgrade
    if git merge --ff-only "${TRAVIS_BRANCH}" ; else
           ERRMSG="Unable to perform a ff-merge against ${TRAVIS_BRANCH}. Aborting attempt."
           comment_on_pr "${ERRMSG}" || echo "${ERRMSG}. Also, no PR exists towards the autoupgrade branch so not logging status there."
           comment_on_pr "${ERRMSG}"
           exit 1
    fi
}

function create_pr_if_not_exists() {
}

function find_pr() {
}

function comment_on_pr() {
    
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
