#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2020-11-30 19:06:40 +0000 (Mon, 30 Nov 2020)
#
#  https://github.com/HariSekhon/bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

# https://www.jetbrains.com/help/teamcity/rest-api-reference.html#Build+Configuration+And+Template+Settings

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090
. "$srcdir/lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Exports all TeamCity BuildTypes (build pipelines) to local JSON configuration files for backup/restore / migration purposes, or even just to backport changes to Git for revision control tracking

If arguments are specified then only downloads those named BuildTypes, otherwise finds and downloads all BuildTypes


Resets buildNumberCounter to 1 in the JSON output to avoid this counter causing non-functional revision control changes


Uses the adjacent teamcity_api.sh and jq (installed by 'make')

See teamcity_api.sh for required connection settings and authentication
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args="[<buildtype1> <buildtype2> ...]"

help_usage "$@"

#min_args 1 "$@"

if [ $# -gt 0 ]; then
    for build_name in "$@"; do
        echo "$build_name"
    done
else
    "$srcdir/teamcity_api.sh" /buildTypes |
    jq -r '.buildType[].id'
fi |
grep -v '^[[:space:]]*$' |
while read -r build_id; do
    filename="$build_id.json"
    timestamp "downloading build '$build_id' to '$filename'"
    output="$("$srcdir/teamcity_api.sh" "/buildTypes/$build_id")"
    # using jq just for formatting
    #jq . > "$filename" || :  # some builds get 400 errors, ignore these
    # reset the buildNumberCounter to 1 every time so that we don't incur pointless revision changes
    build_number_counter_index="$(jq '.settings.property | map(.name == "buildNumberCounter") | index(true)' <<< "$output")"
    jq -r ".settings.property[$build_number_counter_index].value = \"1\"" <<< "$output" > "$filename"
done
