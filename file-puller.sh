#!/bin/bash

# SKIP an entry if...
# - The source repository matches the destination repository

# WARN AND CONTINUE if...
# - A source ref does not exist
# - A source path does not exist

# FAIL AND EXIT 1 if...
# - $FP_DSTROOT does not contain a Git repository
# - Unable to clone a source repository
# - Git user.email and user.name are not provided

validate_config () {

  #
  # Figure env variables, and make them available
  #
  if [ "$GITHUB_ACTIONS" = "true" ]; then
    # FP_ environment variables are set by Action or Workflow
    # Write them to $GITHUB_ENV for re-use in job steps
    echo "
    FP_CONFIG=\"$FP_CONFIG\"
    FP_DSTROOT=\"$FP_DSTROOT\"
    GIT_AUTHOR_EMAIL=\"${GIT_AUTHOR_EMAIL:-$FP_GITEMAIL}\"
    GIT_AUTHOR_NAME=\"${GIT_AUTHOR_NAME:-$FP_GITNAME}\"
    FP_PRHEAD=\"$FP_PRHEAD\"
    FP_SRCROOT=\"$FP_SRCROOT\"
    " >> "$GITHUB_ENV"
  else
    # Use provided env variables or defaults
    FP_CONFIG="${FP_CONFIG:-.file-puller/config.json}"
    FP_DSTROOT="${FP_DSTROOT:-.}"
    if ! GIT_AUTHOR_EMAIL="$(git config user.email)"; then
      echo "FAIL: Git user.email not set?"; exit 1; fi
    if ! GIT_AUTHOR_NAME="$(git config user.name)"; then
      echo "FAIL: Git user.name not set?"; exit 1; fi
    FP_PRHEAD="${FP_PRHEAD:-chore/file-puller}"
    FP_SRCROOT="$(mktemp -d)"
  fi

  #
  # Ensure $FP_DSTROOT contains a Git repository
  #
  if git -C $FP_DSTROOT rev-parse --show-toplevel >/dev/null; then
    :
  else
    echo "FAIL: Is '$FP_DSTROOT' a Git repository?"
    exit 1
  fi
  
  #
  # Ensure each dstPath is unique
  #
  if jq . "$FP_CONFIG" > /dev/null; then
    if [ "$( jq -r '.[].dstPath' "$FP_CONFIG" | sort )" != \
      "$( jq -r '.[].dstPath' "$FP_CONFIG" | sort -u )" ]; then
      echo "FAIL: Invalid config '$FP_CONFIG'. Each dstPath must be unique."
      exit 1;
    fi
  else
    echo "FAIL: Failed to load config '$FP_CONFIG'."
    exit 1
  fi

  return
}

clone_sources () {
  _srcRepos="$( jq -r '.[].srcRepo' "$FP_CONFIG" | sort -u )"
  for _srcRepo in $_srcRepos; do
    # TODO: Handle failure rather than rely on Actions `set -e`
    git clone https://github.com/$_srcRepo $FP_SRCROOT/$_srcRepo
  done
  return
}

pull_files () {
  _dstPaths="$( jq -r '.[].dstPath' "$FP_CONFIG" | sort )"
  for _dstPath in $_dstPaths; do

    # Extract: dstPath.srcRepo, .srcRef, .srcPath, .transform
    IFS=$'\n' arr=( $( jq -r '.[] | select(.dstPath=="'"$_dstPath"'") | .srcRepo, .srcRef, .srcPath, .transform' "$FP_CONFIG" ) )
    _srcRepo="${arr[0]}"
    _srcRef="${arr[1]}"     # Will be "null" if no source ref
    if [ "${arr[2]}" = "null" ]; then _srcPath="$_dstPath";
      else _srcPath="${arr[2]}"; fi
    _transform="${arr[3]}"  # Will be "null" if no transform

    # Fetch and checkout .srcRef, if it's not "null"
    if [ "$_srcRef" != "null" ]; then
      git -C "$FP_SRCROOT/$_srcRepo" fetch origin "$_srcRef"
      git -C "$FP_SRCROOT/$_srcRepo" checkout --quiet FETCH_HEAD
    fi

    # Assemble from- and to- paths
    _frP="$(realpath "$FP_SRCROOT/$_srcRepo/$_srcPath")"
    _toP="$(realpath "$FP_DSTROOT/$_dstPath")"

    # Warn and skip if srcPath is not a regular file
    if [ ! -f "$_frP" ]; then
      echo "WARN: srcPath '$_frP' is not a regular file."
      echo "WARN: Skipping dstPath '$_toP'."
      continue
    fi

    # Copy $FP_SRCROOT/$_srcRepo/$_srcPath to $FP_DSTROOT/$_dstPath
    if [ -d "$_toP" ]; then
      # $_toP is a directory; Append /
      _toP="$_toP/"
    elif [ -f "$_toP" ]; then
      # $_toP is a regular file
    else
      echo "FAIL: '$_toP' unknown type."
      exit 1
    fi
    if [ ! -f "$_frP" ]; then
      # $_frP is not a regular file
      echo "FAIL: '$_frP' must be a file."
      exit 1
    fi
    echo "cp -a \"$FP_SRCROOT/$_srcRepo/$_srcPath\" \"$FP_DSTROOT/$_dstPath\""
    if [ "$_transform" != "null" ]; then
      echo "Apply transform"
    fi
  done;
}

# TODO: YOU ARE HERE

# TODO: Make this fit for use
validate_config
clone_sources
pull_files
exit 1



push_changes () {
  # TODO
  return
}

cleanup () { 
  # TODO
  return
}

usage() { echo "
  Run it, like, './file-puller.sh clone-srcRepos'
  "
  return
}

case "$1" in
  validate-config)
    validate_config;;
  clone-dstRepo)
    clone_dest;;
  clone-srcRepos)
    clone_sources;;
  copy-files)
    pull_files;;
  commit-changes)
    for srcRepo in ; commit changes from src; done;;
  output-diff)
    git diff main; echo shiz;;
  push-changes)
    git push origin main;;
  pull-request)
    gh pulls do something;;
  *)
    usage
    exit 1;;
esac