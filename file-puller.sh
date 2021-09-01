#!/bin/bash

# SKIP an entry if...
# - The source repository matches the destination repository

# FAIL AND CONTINUE if...
# - The source ref does not exist
# - The source path does not exist

# FAIL AND EXIT 1 if...
# - Unable to checkout this repository

# TODO: Make this fit for use
exit 1


FP_CONFIG="${FP_CONFIG:-.file-puller.json}"
FP_TOKEN="$FP_TOKEN"

_dstRepo=$GITHUB_REPO
_dstRef=$GITHUB_REF
_dstPaths="$( jq -r '.[].dstPath' "$FP_CONFIG" | sort )"

_srcRoot=$(realpath .)
_srcRepos="$( jq -r '.[].srcRepo' "$FP_CONFIG" | sort -u )"

usage() { echo "
    Run it, like, './file-puller.sh clone-srcRepos'
    ";
    exit $1;
}

case "$1" in
  validate-config)
    # Ensure dstPath are unique
    exit 0;;
  clone-srcRepos)
    for srcRepo in $srcRepos; do
      git clone https://github.com/$_srcRepo $_srcRoot/$_srcRepo;;
    done;;
  copy-files)
    for _dstPath in $_dstPaths; do
      # Extract: dstPath.srcRepo, .srcRef, .transform
      IFS=$'\n' arr=( $( jq -r '.[] | select(.dstPath=="'"$_dstPath"'") | .srcRepo, .srcRef, .transform' .file-puller.json ) )
      # Fetch and checkout _srcRef
      pushd "$_srcRoot/$_srcRepo"
      git fetch origin "$_srcRef"
      git checkout FETCH_HEAD
      cp -fa $_srcPath $_dstPath
    done;;
  commit-changes)
    for srcRepo; commit changes from src; done;;
  output-diff)
    git diff main; echo shiz;;
  push-changes)
    git push origin main;;
  pull-request)
    gh pulls do something;;
  *)
    usage 1;;
esac