#!/usr/bin/env bash

# Copyright 2024 Vasiliy Vasilyuk <xorcare@gmail.com> All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# See https://github.com/xorcare/go-mod-bump/blob/main/LICENSE

set -e

ARGS=''
PREFIX=''

function help() {
    cat <<EOF
usage: go-mod-bump PARAM [-p|-message-prefix OPTION] [-h|-help] [modules]

Script to elegantly update direct Go modules in separate commits.

Automatically updates dependencies similar to 'go get -u', but
commits the update to each direct module in a separate commit.

Source https://github.com/xorcare/go-mod-bump

EXAMPLES

For update all direct models, use:

    go-mod-bump all

For update one specific direct module, specify its name. For example:

    go-mod-bump github.com/xorcare/pointer

For update multiple direct modules, specify their names. For example:

    go-mod-bump github.com/xorcare/pointer github.com/xorcare/tornado

OPTIONS
    -p <prefix>, -message-prefix=<prefix>
        Add custom prefix to git commit message.

    -h|-help
        Show this message.
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
    -h | -help)
        help
        exit 0
        ;;
    -p | -message-prefix)
        PREFIX="$2"
        shift
        ;;
    --* | -*)
        echo "Illegal option $1"
        echo "For print help use flag -help"
        exit 1
        ;;
    *)
        ARGS="$ARGS $1"
        ;;
    esac
    shift
done

readonly PREFIX ARGS

eval set -- "$ARGS"

function echoerr() {
    if [ ! -t 0 ]; then
        cat <&0 >&2
    fi
    if [ -n "$1" ]; then
        echo "$@" >&2
    fi
}

if [ -z "$1" ]; then
    echoerr <<EOF
go-mod-bump: nothing to do, set argument 'all' or module name(s).
    Also, you can use flag -help for get more examples of usage.
EOF
    exit 0
fi

GO_LIST_FORMAT_DIRECT='{{.Path}}{{if .Indirect}}<SKIP>{{end}}{{if .Main}}<SKIP>{{end}}'
readonly GO_LIST_FORMAT_DIRECT

# shellcheck disable=SC2068
DIRECT_MODULES=$(go list -m -f "$GO_LIST_FORMAT_DIRECT" $@ | grep -v '<SKIP>')
readonly DIRECT_MODULES

GO_LIST_FORMAT_FOR_UPDATE='{{.Path}}@{{.Version}}@{{if .Update}}{{.Update.Version}}{{end}}'
GO_LIST_FORMAT_FOR_UPDATE+='{{if not .Update}}<SKIP>{{end}}' # skip modules without updates.
readonly GO_LIST_FORMAT_FOR_UPDATE

# shellcheck disable=SC2086
MODULES_FOR_UPDATE=$(go list -m -u -f "$GO_LIST_FORMAT_FOR_UPDATE" $DIRECT_MODULES | grep -v '<SKIP>')
readonly MODULES_FOR_UPDATE

function update_module() {
    go get "$1"

    go mod tidy
    go build ./...
}

function bump_module() {
    module=$(echo "$1" | cut -f1 -d@)
    current_version=$(echo "$1" | cut -f2 -d@)
    latest_version=$(echo "$1" | cut -f3 -d@)

    if ! update_module "${module}@${latest_version}" >/dev/null 2>&1 >/dev/null; then
        echoerr "go-mod-bump: failed to update module ${module} from ${current_version} to ${latest_version}"
        echoerr "try to update module manually using commands:"
        echoerr "go get ${module}@${latest_version}"
        echoerr "go mod tidy"
        echoerr "go build ./..."
        git checkout -f HEAD -- go.mod go.sum
        return
    fi

    git reset HEAD -- . >/dev/null
    git add go.mod go.sum >/dev/null
    git commit -a -m "${PREFIX}Bump ${module} from ${current_version} to ${latest_version}" >/dev/null

    echoerr "go-mod-bump: upgraded ${module} ${current_version} => [${latest_version}]"
}

for mdl in $MODULES_FOR_UPDATE; do
    (bump_module "$mdl")
done
