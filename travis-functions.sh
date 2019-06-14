#!/bin/bash

set -eE
set -o pipefail

# Travis CI support functions

function ensure_github_authenticated() {
    git remote remove origin
    git remote add origin "https://${GH_TOKEN}@github.com/madworx/docker-qemu"
}

# Ensure that we can fast-forward towards the 'autoupgrade' branch.
# If that branch doesn't exist - this is a no-op.
function ensure_autoupgrade_branch() {
    ensure_github_authenticated
    if git checkout autoupgrade ; then
        echo "Ensured autoupgrade branch. Checking if we can do fast-forward merge against ${TRAVIS_BRANCH}."
        if ! git merge --ff-only "${TRAVIS_BRANCH}" ; then
            comment_on_pr "Unable to perform a ff-merge against ${TRAVIS_BRANCH}. Aborting attempt."
            exit 1
        fi
    else
        echo 'No existing autoupgrade branch exists. Creating it as a branch of current branch.'
        git checkout -b autoupgrade
    fi
}

function merge_autobuild_against_autoupgrade() {
    ensure_github_authenticated

    # Apply git magick:
    git remote set-branches --add origin autoupgrade
    git fetch origin autoupgrade

    git checkout autoupgrade
    if ! git merge --ff-only "${TRAVIS_BRANCH}" ; then
        comment_on_pr "Unable to perform a ff-merge against ${TRAVIS_BRANCH}. Aborting attempt."
        exit 1
    else
        git push
    fi
}

function create_pr_if_not_exists() {
    echo "not really: create_pr_if_not_exists $*"
}

function find_pr() {
    echo "not really: find_pr $*"
}

function comment_on_pr() {
    echo "not really: comment_on_pr $*"
    #comment_on_pr "${ERRMSG}" || echo "${ERRMSG}. Also, no PR exists towards the autoupgrade branch so not logging status there."
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
    ensure_github_authenticated
    git branch -D "${BRANCH_NAME}" || true
    git push origin :"${BRANCH_NAME}" || true
    git checkout -b "${BRANCH_NAME}"
    git commit -a -m "Reintegration against ${LATEST_QEMU} worked."
    git remote -v
    git push -u origin "${BRANCH_NAME}"
}
