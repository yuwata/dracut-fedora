#!/bin/bash

CMD=${0##*/}
SOURCE_DIR=$(cd $(dirname $0) && pwd)
REPO_NAME=${SOURCE_DIR##*/}
REPO_DIR=${HOME}/git/${REPO_NAME}

HASH_OLD=$(grep -e '^[%#]global gitcommit' ${SOURCE_DIR}/${REPO_NAME}.spec | awk '{ print $3 }')
if [[ -z $HASH_OLD ]]; then
    echo 'error: cannot obtain commit hash.' >&2
    exit 1
fi

if ! git -C $REPO_DIR fetch upstream master; then
    echo "error: `git fetch upstream master` failed." >&2
    exit 11
fi

if ! HASH_NEW=$(git -C $REPO_DIR show-ref --hash refs/remotes/upstream/master); then
    echo "error: `git show-ref` failed." >&2
    exit 12
fi

if [[ "$HASH_NEW" == "$HASH_OLD" ]]; then
    echo 'info: not necessary to update spec file.' >&2
    exit
fi

HASH_OLD_SHORT=${HASH_OLD:0:7}
HASH_NEW_SHORT=${HASH_NEW:0:7}
DATE_OLD=$(grep -e '^[%#]global gitdate' ${SOURCE_DIR}/${REPO_NAME}.spec | awk '{ print $3 }')
DATE_NEW=$(git -C $REPO_DIR log -1 --format='%cd' --date=short ${HASH_NEW} | tr -d -)

VERSION=$(grep -e '^Version:' ${SOURCE_DIR}/${REPO_NAME}.spec | awk '{ print $2 }')

RELEASE_OLD=$(grep -e '^%define dist_free_release' ${SOURCE_DIR}/${REPO_NAME}.spec | awk '{ print $3 }' | sed -e 's/\.git.*$//')
RELEASE_MAIN=$(echo $RELEASE_OLD | sed -e 's/\.[[:digit:]]*//')
RELEASE_SUB_OLD=$(echo $RELEASE_OLD | sed -e 's/[[:digit:]]*\.*//')
if [[ -z $RELEASE_SUB_OLD ]]; then
    RELEASE_SUB_OLD=0
fi

RELEASE_SUB_NEW=$(( $RELEASE_SUB_OLD + 1 ))
RELEASE_NEW=${RELEASE_MAIN}.${RELEASE_SUB_NEW}

WEEKDAY=$(date "+%a")
MONTH=$(date "+%b")
DAY=$(date "+%d")
YEAR=$(date "+%Y")

CHANGE_LOG="Update to latest git snapshot ${HASH_NEW}\n"

sed -e '/^[%#]global gitcommit/ { s/^#/%/; s/'${HASH_OLD}'/'${HASH_NEW}'/ }' \
    -e '/^%global gitdate/ s/'${DATE_OLD}'/'${DATE_NEW}'/' \
    -e '/^%define dist_free_release/ { s/'${RELEASE_OLD}'.*$/'${RELEASE_NEW}'\.git%{gitdate}/ }' \
    -e "/^%changelog/ a\
* ${WEEKDAY} ${MONTH} ${DAY} ${YEAR} Yu Watanabe <watanabe.yu@gmail.com> - ${VERSION}-${RELEASE_NEW}.git${DATE_NEW}\\
- ${CHANGE_LOG}" \
    -i ${SOURCE_DIR}/${REPO_NAME}.spec

git -C $SOURCE_DIR commit -a -m "$(echo -e ${CHANGE_LOG})"
