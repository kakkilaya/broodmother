#!/usr/bin/bash

if [ $1 -eq 1 ] && [ -f links ] && [ ! -f links.tmp ]; then
	exit
fi

if [ -f links.tmp ]; then
	rm links.tmp
fi

path=$(grep -oP '(?<=\<title\>Index of )[^<]+' $2)

path=$(python -c "import urllib.parse; print(urllib.parse.quote(\"$path\"))")

lines=$(grep -oP '(?<=href\=")[^"]+' $2 | tail -n +2)

for line in $lines
do
	echo $3$path$line >> links.tmp
done

if [ -f links.tmp ]; then
	mv links.tmp links
fi
