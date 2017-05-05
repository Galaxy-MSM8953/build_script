#!/bin/bash

function check_oc_enabled {
ARG="--oc"
for i in `seq 0 ${#}`; do
	if [ "${!i}" == "$ARG" ]; then
		logb "\t\tOverclocking is enabled"
		OVERCLOCKED=y
	fi
done
}

PRE_PATCH_FUNCTIONS=("${PRE_PATCH_FUNCTIONS[@]}" "check_oc_enabled")