#!/bin/bash

VERSION=$(cat ~/cromite/build/RELEASE)
CURRENT_RELEASE=$(git -C ~/chromium/src/ rev-parse --verify refs/tags/$VERSION)

ALLPATCHS_E=$(git -C ~/chromium/src/ rev-list HEAD...$CURRENT_RELEASE)

mkdir ~/cromite/build/patches-new
rm ~/cromite/build/patches-new/patch-list

NO_NAME=1

for patch in $ALLPATCHS_E; do

	PATCH_FILE=$(git -C ~/chromium/src/ show -s $patch | grep FILE: | sed 's/FILE://g' | sed 's/^[ \t]*//;s/[ \t]*$//')
	if [[ "$PATCH_FILE" == *"Automated-domain-substitution"* ]]; then
		continue
	fi
	PATCH_MESSAGE=$(git -C ~/chromium/src/ show -s $patch)
	if [[ $PATCH_MESSAGE == *NOEXPORT:* ]] ;
	then
		continue
	fi
	if [[ -z "$PATCH_FILE" ]]; then
		PATCH_FILE=00$(git -C ~/chromium/src/ show -s $patch | head -n 5 | tail -n 1 | xargs | tr " " - | tr [:punct:] -).patch
	fi

	echo $PATCH_FILE >>~/cromite/build/patches-new/patch-list

done

tac ~/cromite/build/patches-new/patch-list >~/cromite/build/patches-new/zz-patch-list.txt
rm ~/cromite/build/patches-new/patch-list
