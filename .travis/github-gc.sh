#!/bin/bash

# Copyright (c) 2020 Damien Ciabrini
# This file is part of ngdevkit


# Disable verbose to prevent leaking credentials
set +x


help() {
    echo "Usage: $0 --repo={user}/{repo} --token={github-api-token} --tag-regex={str} --commit={sha1}" >&2
    exit ${1:-0}
}

error() {
    echo "Error: $1" >&2
    help 1
}

check() {
    if [ $2 != 200 ] && [ $2 != 204 ]; then
        error "unexpected return from '$1' ($2). Aborting"
    fi
}

# ----------------- config parsing -----------------
#
REPO=${TRAVIS_REPO_SLUG:-}
COMMIT=${TRAVIS_COMMIT:-}
GITHUB_TOKEN=
TAG_REGEX=
DRYRUN=

OPTS=$(/usr/bin/getopt -n $0 --long help,dry-run,user:,repo:,token:,tag-regex:,commit: -- $0 $@)
if [ $? != 0 ]; then
    error "parsing arguments failed"
fi

eval set -- "$OPTS"
while true; do
    case "$1" in
        --help) help;;
        --dry-run ) DRYRUN=1; shift ;;
        --user ) USER="$2"; shift 2 ;;
        --repo ) REPO="$2"; shift 2 ;;
        --token ) GITHUB_TOKEN="$2"; shift 2 ;;
        --tag-regex ) TAG_REGEX="$2"; shift 2 ;;
        --commit ) COMMIT="$2"; shift 2 ;;
        -- ) shift; break ;;
        * ) break ;;
    esac
done

if [ -z "$REPO" ]; then
    error "no repository specified"
fi
if [ -z "$GITHUB_TOKEN" ]; then
    error "no token/password specified for GitHub API credentials"
fi
if [ -z "$TAG_REGEX" ]; then
    error "no tag regex specified, cannot filter which tags to remove"
fi
if [ -z "$COMMIT" ]; then
    error "no commit specified, cannot check whether latest GitHub release points to the right code"
fi
if [ -z "$USER" ]; then
    # if unset, extract user from repo slug
    USER=$(echo $REPO | cut -d'/' -f1)
fi
CREDS=$USER:$GITHUB_TOKEN


# ----------------- garbage-collect releases and tags -----------------
#
echo "Downloading releases list from $REPO..."
ret=$(curl -s -w "%{http_code}" -X GET -u $CREDS https://api.github.com/repos/$REPO/releases -o releases)
check "downloading releases list" $ret

# most recent release matching tag_name regex
last_release=$(jq '. | map(select(.tag_name | test("'"$TAG_REGEX"'"))) | sort_by(.created_at) | reverse[0]' releases)
commit=$(echo $last_release | jq -r '.target_commitish')
tag_name=$(echo $last_release | jq -r '.tag_name')
id=$(echo $last_release | jq -r '.id')

if [ "$commit" != "$COMMIT" ]; then
   error "Latest release matching '$TAG_REGEX' in $REPO doesn't point to commit '$COMMIT'. Aborting"
fi

echo "Latest matching release is associated to tag '$tag_name' and points to commit '$COMMIT', keeping it"

# all releases to remove
releases_rm=$(jq -r '.[] | select(.tag_name | test("'"$TAG_REGEX"'")) | select (.id != '"$id"') | .id' releases)
if [ -n "$releases_rm" ]; then
    echo "Deleting all the remaining releases matching '$TAG_REGEX'"
else
    echo "  (no old release detected)"
fi
for i in $releases_rm; do
    tag_name_rm=$(jq -r '.[] | select (.id == '"$i"') | .tag_name' releases)
    echo "  removing release $i pointing to tag $tag_name_rm"
    if [ -z "$DRYRUN" ]; then
        ret=$(curl -s -w "%{http_code}" -X DELETE -u $CREDS https://api.github.com/repos/$REPO/releases/$i)
        check "removing release $i" $ret
        sleep 0.5
    fi
done

echo "Downloading tags list from $REPO..."
ret=$(curl -s -w "%{http_code}" -X GET -u $CREDS https://api.github.com/repos/$REPO/git/refs/tags -o references)
check "downloading tags list" $ret

# all tags to remove
tags_rm=$(jq -r '.[] | select(.ref | test("^refs/tags/'"${TAG_REGEX#^}"'")) | select (.object.sha != "'"$COMMIT"'") | .ref' references)
if [ -n "$tags_rm" ]; then
    echo "Deleting all the remaining tags matching '$TAG_REGEX'"
else
    echo "  (no old tag detected)"
fi
for i in $tags_rm; do
    commit_rm=$(jq -r '.[] | select (.ref == "'"$i"'") | .object.sha' references)
    echo ". Removing tag reference $i pointing to commit $commit_rm"
    if [ -z "$DRYRUN" ]; then
        ret=$(curl -s -w "%{http_code}" -X DELETE -u $CREDS https://api.github.com/repos/$REPO/git/$i)
        check "  removing tag reference $i" $ret
        sleep 0.5
    fi
done
