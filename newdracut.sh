#!/bin/bash

if [[ -f "$HOME/git/dracut/$1" ]]; then
    srcrpm="$HOME/git/dracut/$1"
else
    srcrpm="$1"
fi

[[ -f $srcrpm ]] || exit 0

cp dracut.spec dracut.spec.old
for i in *.patch; do git rm -f $i;done

if rpm -ivh --define "_srcrpmdir $PWD" --define "_specdir $PWD" --define "_sourcedir $PWD" "$srcrpm"; then
	ls *.patch &>/dev/null && git add *.patch
	perl -n -e 'if ($do_print) {print "$_" ;}; if (/^%changelog/) { $do_print=1; }' < dracut.spec.old >> dracut.spec
fi
