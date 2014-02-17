#!/bin/bash
#
# Copyright (C) 2012-2014, SUSE Linux Products GmbH
# Author: Lars Vogdt
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the Novell nor the names of its contributors may be
#   used to endorse or promote products derived from this software without
#   specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#

CONFIG='/etc/mrtg/mrtg-tools.cfg'
CFGMAKER='/usr/bin/cfgmaker'
INDEXMAKER='/usr/bin/indexmaker'
INDEXMAKER_LOGFILE="$(dirname $CONFIG)/".indexmaker-lastrun
CREATE_OUTPUT_BASE_DIR='yes'

if [ -r "$CONFIG" ]; then
	. "$CONFIG"
else
	echo "Could not read $CONFIG - exit" >&2
	exit 1
fi

test -d "$CFGMAKER_CONFIGS" || { 
	echo "$CFGMAKER_CONFIGS is no directory - exit" >&2;
	exit 1;
}

if [ "$RUN_SCRIPTS" == "yes" ]; then
	cd "$CFGMAKER_CONFIGS"

	echo -n "loop begin: " > "$INDEXMAKER_LOGFILE"
	date >> "$INDEXMAKER_LOGFILE"

	if [ ! -d "$OUTPUT_BASE_DIRECTORY" ]; then
		if [ "$CREATE_OUTPUT_BASE_DIR" == "yes" ]; then
			echo "Creating $OUTPUT_BASE_DIRECTORY" >> "$INDEXMAKER_LOGFILE"
			mkdir -p "$OUTPUT_BASE_DIRECTORY"
		else
			echo "$OUTPUT_BASE_DIRECTORY does not exist - exiting" >> "$INDEXMAKER_LOGFILE"
			exit 0;
		fi
	fi
	for i in $(ls *.conf); do
		name=$(echo "$i" | sed "s/\.conf//")
		AVAIL=$(ping -qc3 $name >/dev/null 2>&1; echo $?)
		for skipname in $CFGMAKER_SKIP_CONFIGS ; do
			if [ "$name" == "$skipname" ]; then
				break;
			fi
		done
		if [ "$AVAIL" != "0" ]; then
			echo "Switch $name is not available, skipping" >> "$INDEXMAKER_LOGFILE"
		else
			echo "Creating config for $name ..." >> "$INDEXMAKER_LOGFILE"
			cmd=$(grep -h $CFGMAKER "$i" | sed -e "s|#||")
			eval "$cmd"
			echo "Creating index for $name ..." >> "$INDEXMAKER_LOGFILE"
			env LANG=C $INDEXMAKER --output="$OUTPUT_BASE_DIRECTORY/$name/index.html" --prefix="$OUTPUT_PREFIX" --title="$OUTPUT_TITLE $name" --pagetop="$OUTPUT_PAGETOP" "$i"
		fi
	done
	echo -n "loop complete: " >> "$INDEXMAKER_LOGFILE"
	date >> "$INDEXMAKER_LOGFILE"
fi
