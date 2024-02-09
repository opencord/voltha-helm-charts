#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Copyright 2018-2022 Open Networking Foundation (ONF) and the ONF Contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIESS OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ---------------------------------------------------------------------------
# chart_version_check.sh
# checks that changes to a chart include a change to the chart version
# ---------------------------------------------------------------------------

set -u
# set -euo pipefail

##-------------------##
##---]  GLOBALS  [---##
##-------------------##
declare -i -g force_fail=0
declare -a -g error_stream=()

# declare -A -g ARGV=() # ARGV['debug']=1
# declare -i -g debug=1 # uncomment to enable

## -----------------------------------------------------------------------
## Intent: Display a program banner for logging
## -----------------------------------------------------------------------
# shellcheck disable=SC2120
function banner()
{
    local program="${0##*/}"

    cat <<BANNER

# -----------------------------------------------------------------------
# Running: ${program} $@
# -----------------------------------------------------------------------
# Now: $(date '+%Y-%m-%d %H:%M:%S')
# Git: $(git --version)
# -----------------------------------------------------------------------
# COMPARISON_BRANCH: ${COMPARISON_BRANCH}
#         WORKSPACE: ${WORKSPACE}
# -----------------------------------------------------------------------
BANNER

    return
}

## -----------------------------------------------------------------------
## Intent: Augment a version string for display.  If the given string
##         is empty rewrite to make that detail painfully obvious.
## -----------------------------------------------------------------------
function version_for_display()
{
    local -n ref=$1; shift

    if [[ ${#ref} -eq 0 ]]; then
        ref='?????????????????' # higlight the problem for reporting
    fi
    return
}

## -----------------------------------------------------------------------
## Intent: Use git commands to retrieve chart version embedded within a file
## -----------------------------------------------------------------------
## Given:
##   ref     Indirect var for version string return.
##   path    Repository path to a Chart.yaml file
##   branch  git branch to retrieve
##
## Return:
##   ref     Extracted version string
## -----------------------------------------------------------------------
function get_version_by_git()
{
    local -n ref=$1   ; shift
    local path="$1"   ; shift
    local branch="$1" ; shift
    ref=''

    # -----------------------------------------------------------------------
    # cat "{branch}:{chart}" to stdout: (wanted => 'version : x.y.z')
    # ----------------------------------------------------------------------- 
    readarray -t buffer < <(\
        git show "${branch}:${path}" \
            | grep '^[[:blank:]]*version[[:blank:]]*:'\
        )

    # Extract version string
    if [[ ${#buffer[@]} -ne 1 ]]; then
        ref='' # Highly forgiving (display only)
    else
        local raw="${buffer[0]}"

        # Extract value, split on whitespace, colon, comment or quote
        readarray -t fields < <(awk -F '[[:blank:]:#"]+' '{print $2}' <<<"$raw")
        ref="${fields[0]}"
    fi

    return
}

## -----------------------------------------------------------------------
## Intent: Display a log summary entry then exit with status.
## -----------------------------------------------------------------------
function summary_status_with_exit()
{
    local exit_code=$1; shift
    local program="${0##*/}"
    local summary=''
    [[ $# -gt 0 ]] && { summary=" - $1"; shift; }

    ## -----------------------------------
    ## status override courtesy of error()
    ## -----------------------------------
    declare -i -g force_fail
    if [ $force_fail -eq 1 ]; then exit_code=$force_fail; fi

    ## --------------------------
    ## Set summary display string
    ## --------------------------
    case "$exit_code" in
	0) status='PASS' ;;
	*) status='FAIL' ;;
    esac

    [[ $# -gt 0 ]] && formatStream "$@"

    echo
    echo "[$status] ${program} ${summary}"

    exit "$exit_code"
}

## -----------------------------------------------------------------------
## Intent: Display an error and configure report summary_status as FAIL
## -----------------------------------------------------------------------
function error()
{
    declare -i -g force_fail=1
    declare -a -g error_stream

    # shellcheck disable=SC2124
    local error="[ERROR] $@"
    error_stream+=("$error")
    echo "$error"
    return
}

## -----------------------------------------------------------------------
## Intent: Given a list (header and data) format contents as a log entry
## -----------------------------------------------------------------------
##  Usage: displayList --banner "List of something" "${data_stream[@]}"
## -----------------------------------------------------------------------
function displayList()
{
    local indent=''
    while [ $# -gt 0 ]; do
	local arg="$1"
	case "$arg" in
	    -*banner)  shift; echo "$1"     ;;
	    -*indent)  shift; indent="$1"   ;;
	    -*tab-2)   echo -n '  '         ;;
	    -*tab-4)   echo -n '    '       ;;
	    -*tab-6)   echo -n '      '     ;;
	    -*tab-8)   echo -n '        '   ;;
	    -*newline) echo;                ;;
	    -*tab)     echo -n '    '       ;;
	    *) break                        ;;
	esac
	shift
    done

    for line in "$@";
    do
	echo -e "  ${indent}$line"
    done
    return
}

## -----------------------------------------------------------------------
## Intent: Program init, provide defaults for globals, etc.
## -----------------------------------------------------------------------
function init()
{
    # when not running under Jenkins, use current dir as workspace
    #   o [TODO] - Perform a secondary username check to guard against a
    #     jenkins/bash env hiccup leaving WORKSPACE= temporarily undefined.
    WORKSPACE=${WORKSPACE:-.}
    COMPARISON_BRANCH="${COMPARISON_BRANCH:-opencord/master}"
    return
}

## -----------------------------------------------------------------------
## Intent: Remove quotes, whitespace & garbage from a string
## -----------------------------------------------------------------------
## ..seealso: https://www.regular-expressions.info/posixbrackets.html
## -----------------------------------------------------------------------
function filter_codes()
{
    declare -n val="$1"; shift             # indirect
    val="${val//[\"\'[:blank:][:cntrl:]]}" # [:punct:] contains hyphen
    return
}

## -----------------------------------------------------------------------
## Intent: Detect and report VERSION file changes
## -----------------------------------------------------------------------
## :param path: Path to a Chart.yaml file.
## :type  path: str
##
## :param branch: Comparsion baranch (?-remote-?)
## :type  branch: str
##
## :return: true if embedded version string was modified.
## :rtype:  int
## -----------------------------------------------------------------------
## ..note: What about change detection for: apiVersion, appVersion (?)
## -----------------------------------------------------------------------
function version_diff()
{
    local path="$1";         shift
    local branch="$1";       shift

    declare -n old_var="$1"; shift # indirect
    declare -n new_var="$1"; shift # indirect

    old_var=''
    new_var=''
    readarray -t delta < <(git diff -p "$branch" -- "$path")

    local modified=0
    if [ ${#delta[@]} -gt 0 ]; then # modified

	#----------------------------------------
	# diff --git a/voltha-adapter-openolt/Chart.yaml [...]
	# --- a/voltha-adapter-openolt/Chart.yaml
	# +++ b/voltha-adapter-openolt/Chart.yaml
	# @@ -14,7 +14,7 @@
	# ---
	# -version: "2.11.3"   (====> 2.11.3)
	# +version: "2.11.8"   (====> 2.11.8)
	#----------------------------------------
	local line
	for line in "${delta[@]}";
	do
	    # [TODO] Replace awk with string builtins to reduce shell overhead.
	    case "$line" in
		-version:*)
		    modified=1
		    readarray -t tmp < <(awk '/^\-version:/ { print $2 }' <<<"$line")
		    # shellcheck disable=SC2034
		    old_var="${tmp[0]}"
		    filter_codes 'old_var'
		    ;;
		+version:*)
		    readarray -t tmp < <(awk '/^\+version:/ { print $2 }' <<<"$line")
		    # shellcheck disable=SC2034
		    new_var="${tmp[0]}"
		    filter_codes 'new_var'
		    ;;
	    esac
	done
    fi

    [ $modified -ne 0 ] # set $? for if/then/elif use: "if version_diff; then"
    return
}

## -----------------------------------------------------------------------
## Intent: Gather a list of Chart.yaml files from the workspace.
## -----------------------------------------------------------------------
function gather_charts()
{
    declare -n varname="$1"; shift
    readarray -t varname < <(find . -name 'Chart.yaml' -print)

    local idx
    for (( idx=0; idx<${#varname[@]}; idx++ ));
    do
	local val="${varname[idx]}"
	if [ ${#val} -lt 2 ]; then continue; fi

	# Normalize: remove './' to support path comparison
	if [[ "${val:0:2}" == './' ]]; then
	    varname[idx]="${val:2:${#val}}"
	    [[ -v debug ]] && echo "[$idx] ${varname[$idx]}"
	fi
    done

    [[ -v debug ]] && declare -p varname
    return
}

## -----------------------------------------------------------------------
## Intent: Given a chart file and complete list of modified files
##   display a list of files modified in the chart directory.
## -----------------------------------------------------------------------
## :param chart: path to a Chart.yaml file
## :type  chart: str
##
## :param varname: A list files modified in a git sandbox.
## :type  varname: list, indirect
## -----------------------------------------------------------------------
function report_modified()
{
    local chart="$1"; shift
    local dir="${chart%/*}"
    # shellcheck disable=SC2178
    declare -n varname="$1"; shift

    ## ---------------------------------------------
    ## Gather files contained in the chart directory
    ## ---------------------------------------------
    declare -a found=()
    for val in "${varname[@]}";
    do
	case "$val" in
	    */Chart.yaml) ;; # special case
	    "${dir}"*) found+=("$val") ;;
	esac
    done

    ## --------------------------------------------
    ## Display results when modified files detected
    ## --------------------------------------------
    if [ ${#found[@]} -gt 0 ]; then
	declare -a stream=()
	stream+=('--tab-4')
	stream+=('--banner' "Files Changed: $dir")
	stream+=('--tab-6') # really --tab-8
	stream+=("${found[@]}")
	displayList "${stream[@]}"
    fi

    [ ${#found[@]} -gt 0 ] # set $? for if/else
    return
}

## -----------------------------------------------------------------------
## Intent: Gather a list of Chart.yaml files from the workspace.
## -----------------------------------------------------------------------
declare -a -g charts=()
declare -a -g changes_remote=()
declare -a -g untracked_files=()
function gather_state()
{
    local branch="$1"; shift

    gather_charts 'charts'
    [[ -v debug ]] && declare -p charts

    readarray -t changes_remote < <(git diff --name-only "$branch")
    [[ -v debug ]] && declare -p changes_remote

    readarray -t untracked_files < <(git ls-files -o --exclude-standard)
    [[ -v debug ]] && declare -p untracked_files

    return
}

# shellcheck disable=SC1073
##----------------##
##---]  MAIN  [---##
##----------------##
init
# shellcheck disable=SC2119
banner
gather_state "$COMPARISON_BRANCH"

chart=''
for chart in "${charts[@]}";
do
    [[ -v debug ]] && echo -e "\nCHART: $chart"

    ## ---------------------------
    ## Detect VERSION file changes
    ## ---------------------------
    declare -i chart_modified=0
    old=''
    new=''
    if version_diff "$chart" "$COMPARISON_BRANCH" 'old' 'new'; then
        version_for_display new
	suffix="($old => $new)" # display verion deltas in the right margin
	printf '[CHART] %-60s %s\n' "$chart" "$suffix"
	chart_modified=1
    else
        if [[ ${#old} -eq 0 ]]; then
            get_version_by_git old "$chart" "$COMPARISON_BRANCH"
        fi	
        version_for_display old
	suffix="($old)"
	printf '[CHART] %s\n' "$chart"
        new="$old"
    fi

    ## -----------------------------------
    ## Report modified files for the chart
    ## -----------------------------------
    declare -a combo_list=()
    combo_list+=("${changes_remote[@]}")
    combo_list+=("${untracked_files[@]}")
    if report_modified "$chart" 'combo_list';
    then
	    if [ $chart_modified -eq 0 ]; then
            version_for_display new
	        suffix="($old)"
	        error "Chart modified but version unchanged: ${chart} ${suffix}"
	    fi
    fi

done

## ---------------------------
## Report summary: local edits
## ---------------------------
if [[ -x changes_remote ]] && [ ${#changes_remote} -gt 0 ]; then # local_edits
    displayList \
	'--newline'                 \
	'--banner' 'Changed Files:' \
	"${changes_remote[@]}"
fi

## -------------------------------
## Report summary: untracked files
## -------------------------------
if [ ${#untracked_files[@]} -gt 0 ]; then
    displayList \
	'--newline'                   \
	'--banner' 'Untracked Files:' \
	"${untracked_files[@]}"
fi

## ---------------------------------
## Report summary: problems detected
## ---------------------------------
declare -a -g error_stream
if [ ${#error_stream[@]} -gt 0 ]; then
    displayList \
	'--newline'                 \
	'--banner' 'Error Sumamry:' \
	"${error_stream[@]}"
fi

summary_status_with_exit $?

# -----------------------------------------------------------------------
# Running: chart_version_check.sh
# -----------------------------------------------------------------------
# Now: 2022-12-09 03:10:52
# Git: git version 2.34.1
# -----------------------------------------------------------------------
# COMPARISON_BRANCH: origin/master
#         WORKSPACE: .
# -----------------------------------------------------------------------
# [CHART] voltha-adapter-openolt/Chart.yaml                            (2.11.3 => 2.11.8)
# [CHART] voltha-tracing/Chart.yaml
# [CHART] voltha/Chart.yaml
#    Files Changed: voltha-tracing
#        voltha-tracing/values.yaml
# [ERROR] Chart modified but version unchanged: voltha-tracing
# [CHART] voltha/Chart.yaml
# -----------------------------------------------------------------------

# [SEE ALSO
# ---------------------------------------------------------------------------
# https://www.regular-expressions.info/posixbrackets.html (character classes)
# ---------------------------------------------------------------------------
