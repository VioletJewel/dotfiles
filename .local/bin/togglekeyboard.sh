#!/usr/bin/dash

for id in $(xinput --list | grep 'AT Translated Set 2 keyboard' | cut -f2 | cut -d= -f2);
do
  if xinput list-props "$id" | egrep 'Device Enabled\s+\S+\s+1' >/dev/null 2>&1;
  then
    xinput disable "$id";
  else
    xinput enable "$id";
  fi;
done;
