#!/bin/sh

# TODO: find touchpad name on new system
id="$(xinput --list --id-only 'ELAN1200:00 04F3:30BA Touchpad')";
if xinput list-props $id | egrep 'Device Enabled\s+\S+\s+1' >/dev/null 2>&1;
then
  xinput disable "$id";
else
  xinput enable "$id";
fi;
