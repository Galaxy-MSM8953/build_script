#! /bin/bash
# Copyright (C) 2017 Vincent Zvikaramba
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

lock_name=".lock"
lock=

function check_if_build_running {

	lock="${BUILD_TOP}/${lock_name}"

	exec 200>${lock}

	logr "Attempting to acquire lock..."

	# loop if we can't get the lock
	while true; do
		flock -n 200
		if [ $? -eq 0 ]; then
			break
		else
			printf "%c" "."
			sleep 10
		fi
	done

	# set the pid
	pid=$$
	echo ${pid} 1>&200

	logr "Lock acquired. PID is ${pid}"
}

function clean_target {
	#start cleaning up
	logb "Removing temp dir..."
	rm -r $BUILD_TEMP
	logb "Cleaning build dir..."
	cd ${ANDROID_BUILD_TOP}/
	logb "Removing lock..."
	rm ${lock}

	if [ "x${CLEAN_TARGET_OUT}" != "x" ] && [ ${CLEAN_TARGET_OUT} -eq 1 ]; then
		if [ "x$BUILD_TARGET" == "xotapackage" ]; then
			make clean
		fi
	fi
}

function exit_on_failure {
	$@ 2>/dev/null
	exit_error $?
}

function exit_error {
	if [ "x$1" != "x" ] && [ "$1" -ne 0 ]; then
		logr "Error, aborting..."
		if [ "x$SILENT" != "x1" ]; then
			dateStr=`TZ='UTC' date +'[%H:%M:%S UTC]'`
			textStr="${dateStr}[${BUILD_TARGET}] ${distroTxt} ${ver} build %23${JOB_BUILD_NUMBER} for ${DEVICE_NAME} device on ${USER}@${HOSTNAME} aborted."
			wget "https://api.telegram.org/bot${BUILD_TELEGRAM_TOKEN}/sendMessage?chat_id=${BUILD_TELEGRAM_CHATID}&text=${textStr}" -O - > /dev/null 2>/dev/null
		fi
		# remove the temp dir
		logr "Removing temp dir..."
		rm -rf $BUILD_TEMP
		logr "Removing lock..."
		rm ${lock}
		exit 1
	fi
}

# PRINTS A FORMATTED HEADER TO POINT OUT WHAT IS BEING DONE TO THE USER
function echoText() {
    echo -e ${RED}
    echo -e "====$( for i in $( seq ${#1} ); do echo -e "=\c"; done )===="
    echo -e "==  ${1}  =="
    echo -e "====$( for i in $( seq ${#1} ); do echo -e "=\c"; done )===="
    echo -e ${RESTORE}
}

# FORMATS THE TIME
function format_time() {
    MINS=$(((${1}-${2})/60))
    SECS=$(((${1}-${2})%60))
    if [[ ${MINS} -ge 60 ]]; then
        HOURS=$((${MINS}/60))
        MINS=$((${MINS}%60))
    fi

    if [[ ${HOURS} -eq 1 ]]; then
        TIME_STRING+="1 HOUR, "
    elif [[ ${HOURS} -ge 2 ]]; then
        TIME_STRING+="${HOURS} HOURS, "
    fi

    if [[ ${MINS} -eq 1 ]]; then
        TIME_STRING+="1 MINUTE"
    else
        TIME_STRING+="${MINS} MINUTES"
    fi

    if [[ ${SECS} -eq 1 && -n ${HOURS} ]]; then
        TIME_STRING+=", AND 1 SECOND"
    elif [[ ${SECS} -eq 1 && -z ${HOURS} ]]; then
        TIME_STRING+=" AND 1 SECOND"
    elif [[ ${SECS} -ne 1 && -n ${HOURS} ]]; then
        TIME_STRING+=", AND ${SECS} SECONDS"
    elif [[ ${SECS} -ne 1 && -z ${HOURS} ]]; then
        TIME_STRING+=" AND ${SECS} SECONDS"
    fi

    echo ${TIME_STRING}
}

# CREATES A NEW LINE IN TERMINAL
function newLine() {
    echo -e ""
}

# PRINTS AN ERROR IN BOLD RED
function reportError() {
    RED="\033[01;31m"
    RESTORE="\033[0m"

    echo -e ""
    echo -e ${RED}"${1}"${RESTORE}
    if [[ -z ${2} ]]; then
        echo -e ""
    fi
}

# PRINTS AN WARNING IN BOLD YELLOW
function reportWarning() {
    YELLOW="\033[01;33m"
    RESTORE="\033[0m"

    echo -e ""
    echo -e ${YELLOW}"${1}"${RESTORE}
    if [[ -z ${2} ]]; then
        echo -e ""
    fi
}
