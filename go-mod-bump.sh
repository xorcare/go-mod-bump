#!/usr/bin/env bash

# Copyright 2024 Vasiliy Vasilyuk <xorcare@gmail.com> All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# See https://github.com/xorcare/go-mod-bump/blob/main/LICENSE

# Script to elegantly update direct Go modules in separate commits.
#
# Automatically updates dependencies similar to `go get -u`, but commits the update to each direct
# module in a separate commit.
#
# Source https://github.com/xorcare/go-mod-bump

set -e

function echoerr() {
    echo "$@" >&2
}

if [ -z "$1" ]; then
    echoerr <<EOF
go-mod-bump: nothing to do, set argument 'all', 'go' or module name(s), for example:"
    go-mod-bump all"
    go-mod-bump go"
    go-mod-bump github.com/xorcare/pointer"
    go-mod-bump github.com/xorcare/pointer github.com/xorcare/tornado"
EOF
    exit 0
fi

GO_LIST_FORMAT_DIRECT='{{.Path}}{{if .Indirect}}<SKIP>{{end}}'
readonly GO_LIST_FORMAT_DIRECT

# shellcheck disable=SC2068
DIRECT_MODULES=$(go list -f "$GO_LIST_FORMAT_DIRECT" -m $@ | grep -v '<SKIP>')
readonly DIRECT_MODULES

GO_LIST_FORMAT_FOR_UPDATE='{{.Path}}@{{.Version}}@{{if .Update}}{{.Update.Version}}{{else}}<SKIP>{{end}}{{if .Indirect}}<SKIP>{{end}}'
readonly GO_LIST_FORMAT_FOR_UPDATE

# shellcheck disable=SC2086
MODULES_FOR_UPDATE=$(go list -f "$GO_LIST_FORMAT_FOR_UPDATE" -m -u $DIRECT_MODULES | grep -v '<SKIP>')
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
    git cm -a -m "Bump ${module} from ${current_version} to ${latest_version}" >/dev/null

    echoerr "go-mod-bump: upgraded ${module} ${current_version} => [${latest_version}]"
}

for mdl in $MODULES_FOR_UPDATE; do
    (bump_module "$mdl")
done
