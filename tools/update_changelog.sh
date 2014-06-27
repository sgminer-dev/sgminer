#!/bin/sh

FILE="$(dirname "$0")/../ChangeLog"
UPDATECMD="git log --oneline --decorate"

echo "Updated on `date`." > $FILE
echo "If working with git, use \`$UPDATECMD\` for latest change log." >> $FILE
echo "------------------------------------------------------------------------" >> $FILE
$UPDATECMD >> $FILE
