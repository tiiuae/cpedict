#!/bin/bash

# SPDX-FileCopyrightText: 2023 Technology Innovation Institute (TII)
#
# SPDX-License-Identifier: Apache-2.0

################################################################################

set -x # debug
set -e # exit immediately if a command fails
set -u # treat unset variables as an error and exit
set -o pipefail # exit if any pipeline command fails

################################################################################

# Script's directory
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# Output file path
OUT_FILE="$SCRIPT_DIR/data/cpes.csv"
# NVD CPE dictionary URL 'legacy' data feed
NVD_URL="https://nvd.nist.gov/feeds/xml/cpe/dictionary/official-cpe-dictionary_v2.3.xml.gz"
# Community maintained NVD data mirror in the legacy data feed format
NVD_FKIE_URL="https://github.com/fkie-cad/nvd-json-data-feeds/archive/refs/heads/main.tar.gz"
# Return values
TRUE=0; FALSE=1;

################################################################################

test_url () {
    url="$1"
    status=$(curl --head --silent "$url" | head -n 1)
    if echo "$status" | grep -q 404; then
        err_print "Failed URL test: $url"
        return "$FALSE"
    fi
    return "$TRUE"
}

download () {
    url="$1"
    if test_url "$url"; then
        echo "[+] Downloading: '$url'"
        curl -LO "$url"
    fi
}

scrape_cpe_gzs () {
    outfile="$1"
    # Print the header line
    echo "\"vendor\",\"product\"" >"$outfile"

    # Find unique CPEs by (vendor:product), print them to outfile

    if ! gzip -dcf -- *.gz | # uncompress all gz-files to stdout
        # match cpe 2.3 identifiers with type 'a' (application)
        grep -aPo "cpe:2\.3:[a]:([^:]+:)+" |
        # replace all '\\' with '\' (possible double escape sequence)
        sed -E 's|\\\\|\\|g' |
        # replace all '\:' with '!COLON!' (possible escaped ':' in cpe values)
        sed -E 's|\\:|!COLON!|g' |
        # select the cpe values we are interested (vendor:product)
        cut -d":" -f4-5 |
        # remove duplicate and empty lines
        sort | uniq | sed -E '/^$/d' |
        # quote all cpe identifiers in the output
        sed -E 's|([^:]+):([^:]+)|"\1","\2"|g' |
        # replace all '!COLON!' with '\:'
        sed -E 's|!COLON!|\\:|g' \
        >>"$outfile" # write the results to outfile
    then
        err_print "Scrape failed"
        exit 1
    fi
}

sanity_check_cpedict () {
    cpedict="$1"
    out_lines=$(sed -n '$=' "$cpedict")
    if [ "$out_lines" -le 10000 ]; then
        err_print "unexpected output in '$outfile'"
        return "$FALSE"
    fi
    return "$TRUE"
}

read_cpe_data () {
    download "$NVD_URL"
    download "$NVD_FKIE_URL"
    tmpout="cpedata.txt"
    echo "" >"$tmpout"
    scrape_cpe_gzs "$tmpout"
    if sanity_check_cpedict "$tmpout"; then
        cp "$tmpout" "$OUT_FILE"
        echo "[+] Updated cpedict at: '$OUT_FILE'"
    fi
}

################################################################################

exit_unless_command_exists () {
    if ! [ -x "$(command -v "$1")" ]; then
        err_print "command '$1' is not installed" >&2
        exit 1
    fi
}

err_print () {
    RED_BOLD='\033[1;31m'
    NC='\033[0m'
    # If stdout is to terminal print colorized error message, otherwise print
    # with no colors
    if [ -t 1 ]; then
        printf "${RED_BOLD}Error:${NC} %s\n" "$1" >&2
    else
        printf "Error: %s\n" "$1" >&2
    fi
}

on_exit () {
    if [ -d "$MYWORKDIR" ]; then
        rm -rf "$MYWORKDIR"
    fi
}


################################################################################

main () {
    exit_unless_command_exists "curl"
    exit_unless_command_exists "gzip"
    exit_unless_command_exists "sort"
    exit_unless_command_exists "uniq"
    exit_unless_command_exists "cut"
    exit_unless_command_exists "sed"
    read_cpe_data
    exit 0
}

################################################################################

exit_unless_command_exists "mktemp"
MYWORKDIR="$(mktemp -d)"
echo "[+] Using WORKDIR: '$MYWORKDIR'"
trap on_exit EXIT
cd "$MYWORKDIR"
main

################################################################################
