#!/usr/bin/bash

APPDIR="$HOME/.spider"
LISTFILE="$APPDIR/index-sites"
LOGFILE="$APPDIR/log"
LINKSFILE="$APPDIR/links"
LINKSTMP="$APPDIR/links-new"
PREFIX="$APPDIR/sites"

function say {
	echo "[$(date)] $1." >> $LOGFILE
}

function quit {
	say "spider thread for $1 terminated"
	exit
}

function crawl {
	option=""
	if [ $1 -eq 0 ]; then
		say "started crawling $2"

		if [ -d "$PREFIX/$2" ]; then
			say "clearing old index files in $PREFIX/$2 .."

			find "$PREFIX/$2" -type f -name index.html -execdir rm "{}" ";"

			if [ $? -eq 0 ]; then
				say "successfully cleared old index files in $PREFIX/$2 "
			else
				say "error: could not clear old index files in $PREFIX/$2 . halting thread"
				quit $2
			fi
		fi
	else
		say "resumed crawling $2"
		option="-nc"
	fi

	say "retrieving index files from $2 .."

	wget $option -r -l inf --accept-regex '.*/$' \
		--wait=60 --random-wait --tries=inf \
		--retry-connrefused \
		--execute "robots=off" \
		--quiet \
		-P $PREFIX $2

	if [ $? -ne 0 ]; then
		say "retrieved index files from $2 . some errors occured. (wget exit code: $?)"
	else
		say "successfully retrieved index files from $2 "
	fi
}

function grab {
	if [ ! -d "$PREFIX/$2" ]; then
		say "error: cannot grab links for $2 . $PREFIX/$2 does not exist"
		quit $2
	fi

	if [ $1 -eq 0 ]; then
		say "started grabbing links from $2 "
	else
		say "resumed grabbing links from $2 "
	fi

	find "$PREFIX/$2" -type f -name index.html -execdir grab-link.sh $1 "{}" "$2" ";"
		
	if [ $? -ne 0 ]; then
		say "error: failed to grab all links from $2 . halting thread"
		quit $2
	else
		say "successfully grabbed all links from $2 "
	fi
}

function spider-site {
	STATFILE="$APPDIR/$2.status"

	if [ $1 -eq 0 ]; then
		echo "0" > $STATFILE
		crawl $1 $2
		echo "1" > $STATFILE
		grab $1 $2
		rm $STATFILE
	else
		say "checking status for $2 .."

		if [ ! -f $STATFILE ]; then
			say "nothing to do for $2 . halting thread"
			quit $2
		fi

		case "$(cat $STATFILE)" in
			0)
				crawl $1 $2
				echo "1" > $STATFILE
				;&
			1)
				grab $1 $2
				rm $STATFILE
				;;
		esac
	fi

	quit $2
}

say "spider started"

if [ -n "$1" ] && [ "$1" != "-c" ]; then
	say "invalid option $1. spider terminated"
	exit
fi

if [ ! -f $LISTFILE ]; then
	say "$LISTFILE not found. spider terminated"
	exit
fi

option=0

if [ "$1" == "-c" ]; then
	option=1
fi

for site in $(cat $LISTFILE); do
	say "spawning thread for $site .."
	spider-site $option $site &
done

wait

say "all threads completed. spider terminated"
