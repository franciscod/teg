#!/bin/bash

# name: build.sh
# desc: Helper script to build teg

handle_exit() {
  local FOUND_FILE
  local FILE_NAME
  FOUND_FILE=0

  for FILE_NAME in teg*test.log
  do
    FOUND_FILE=1
    echo "---8<----8<----8<----8<----8<- $FILE_NAME ---8<----8<----8<----8<-"
    cat "$FILE_NAME"
  done

  if test "$FOUND_FILE" = "0"
  then
    echo "No test log found" >&2
  fi

  exit "${EXIT_CODE}"
}

teg_build(){
  local SCRIPT_DIR="$1"
  local BUILD_DIR="$2"

  # create the autotools build machinery. 
  (cd "${SCRIPT_DIR}" && bash -eu autogen.sh)

  mkdir "${BUILD_DIR}"
  cd "${BUILD_DIR}"

  # Make sure that the build artifacts are not sneaking into the VCS
  echo '*' > .gitignore

  # Currently teg needs to know the run time path during configuration.
  # See issue #21
  "${SCRIPT_DIR}/configure" --enable-warnings-as-errors --enable-maintainer-mode "--prefix=${PWD}/DD" "CFLAGS=-Wall -Wextra"

  set +e
  # We need to do some work regardless if make succeedes or fails. So here we
  # don't stop on a failure, but preserve the exit code for later usage.
  make all check
  EXIT_CODE="$?"
  set -e
}

# ===========================================================================

set -o errexit  # script exit when a command fails ( add "... || true" to allow fail)
set -o nounset  # script exit when it use undeclared variables
set -o pipefail # exit status of last command that throws a non-zero exit code

trap handle_exit 0 SIGHUP SIGINT SIGQUIT SIGABRT SIGTERM

# if we called the script via a symbolic link
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
readonly SCRIPT_DIR

EXIT_CODE=23

# Main
teg_build "$SCRIPT_DIR" "$SCRIPT_DIR/bd"
