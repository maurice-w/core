#!/bin/sh

# Copyright (C) 2016-2024 Franco Fichtner <franco@opnsense.org>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
# OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

. /usr/local/opnsense/scripts/firmware/config.sh

DO_RANDOM=
DO_SCRIPT=
DO_UNLOCKED=

while getopts r:s:u OPT; do
	case ${OPT} in
	r)
		DO_RANDOM="-r $(jot -r 1 1 ${OPTARG})"
		;;
	s)
		DO_SCRIPT="-s ${OPTARG}"
		;;
	u)
		DO_UNLOCKED="-u"
		;;
	*)
		# ignore unknown
		;;
	esac
done

shift $((OPTIND - 1))

if [ -n "${DO_SCRIPT}" ]; then
	COMMAND=${DO_SCRIPT#"-s "}
else
	FOUND=

	for COMMAND in ${COMMANDS}; do
		if [ "${1}" = ${COMMAND} ]; then
			FOUND=1
			break;
		fi
	done

	if [ -n "${FOUND}" ]; then
		COMMAND=${BASEDIR}/${1}.sh
	else
		COMMAND=
	fi

	shift
fi

# make sure the script exists
if [ ! -f "${COMMAND}" ]; then
	exit 0
fi

if [ -n "${DO_RANDOM}" ]; then
	sleep ${DO_RANDOM#"-r "}
fi

if [ -z "${DO_UNLOCKED}" ]; then
	${FLOCK} -n -o ${LOCKFILE} ${COMMAND} "${@}"
else
	env LOCKFILE=/dev/null ${COMMAND} "${@}"
fi

RET=${?}

# backend expects us to avoid returning errors
if [ -n "${DO_SCRIPT}" ]; then
	exit ${RET}
fi
