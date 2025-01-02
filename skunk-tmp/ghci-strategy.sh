#!/bin/sh
#
# This script facilitates building Chromium within the limitations of the
# GitHub CI environment.
#
# Usage: ghci-strategy.sh SPLIT TARGET ...
#
# Example: ghci-strategy.sh 8 chrome chromedriver mini_installer
#
# The GitHub CI environment imposes two notable constraints:
#
# 1. A single job cannot run longer than six hours, and
#
# 2. While multiple jobs can run concurrently, no network communication is
#    permitted between them.
#
# A single GitHub runner cannot complete the u-c build due to #1, and a
# distributed-compilation solution like distcc cannot be used due to #2.
# An alternative solution, then, is to carve up the u-c build into multiple
# chunks that can be built independently.
#
# The build strategy implemented here divides the build into three stages:
#
#   Stage 1: Produce most of the generated source code.
#
#   Stage 2: Build most of the Windows-side object (.obj) files. This is
#            naturally the most CPU-intensive stage.
#
#   Stage 3: Build the remaining objects, and link everything together
#
# Stages 1 and 3 run on a single system, but stage 2 can be divided across
# several (see the "split" variable below). Each stage inherits the build
# outputs of the preceding ones.
#
# This script generates several files, the most notable of which are
#
#   ghci-stage1.ninja: Stage 1 build (target "ghci-stage1").
#
#   ghci-stage2.ninja: Stage 2 builds (target "part1", "part2", ...)
#
# Stage 3 has no special files/targets; just use the normal Ninja
# invocation with your original intended build targets.
#

split="$1"
shift
targets="$*"

export LC_COLLATE=C
unset NINJA_STATUS

make_ninja_file()
{
	local target="$1"
	local dep_list_file="$2"

	(echo 'subninja build.ninja'
	 echo
	 echo "build $target: phony \$"
	 awk '{ print "    " $0 " $" }' $dep_list_file
	 echo)
}

check_for_heavyweight_dep()
{
	local dep_list_file="$1"

	make_ninja_file \
		ghci-check \
		$dep_list_file \
	> ghci-check.tmp.ninja

	ninja -f ghci-check.tmp.ninja -t inputs ghci-check > ghci-check.tmp.txt

	if grep -Fqx \
		-e chrome.dll.lib \
		-e resources.pak \
		-e gen/chrome/chrome_resource_allowlist.txt \
		ghci-check.tmp.txt
	then
		echo "Error: $dep_list_file contains dependency on heavyweight target"
		exit 1
	fi
}

########

echo "Build targets: $targets"

ninja -t inputs $targets > ghci-inputs.tmp.txt

cat ghci-inputs.tmp.txt \
| grep -E '\.inputdeps(\.stamp)?$' \
| grep -v '/chrome/chrome_initial\.inputdeps' \
> ghci-inputdeps.txt

echo "$(wc -l < ghci-inputdeps.txt) inputdeps targets to build in stage 1"
test -s ghci-inputdeps.txt || exit

check_for_heavyweight_dep ghci-inputdeps.txt

########

cat ghci-inputs.tmp.txt \
| grep -E '^obj/\S+\.o(bj)?$' \
| grep -v '/chrome/chrome_initial/' \
| grep -v '/chrome/packed_resources_integrity/' \
> ghci-objects.txt

echo "$(wc -l < ghci-objects.txt) objects to build in stages 1 and 2"
test -s ghci-objects.txt || exit

check_for_heavyweight_dep ghci-objects.txt

# note: re-using file from above check
cat ghci-check.tmp.txt \
| grep -e '^phony/' -e '\.stamp$' \
| grep -Ev '\.inputdeps(\.stamp)?$' \
> ghci-objdeps.txt

echo "$(wc -l < ghci-objdeps.txt) additional object dependencies to build in stage 1"

########

sort ghci-inputdeps.txt ghci-objdeps.txt > ghci-stage1.tmp.txt

make_ninja_file ghci-stage1 ghci-stage1.tmp.txt > ghci-stage1.ninja

ninja -f ghci-stage1.ninja -n ghci-stage1 > ghci-stage1-steps.tmp.txt
test -s ghci-stage1-steps.tmp.txt || exit
steps=$(wc -l < ghci-stage1-steps.tmp.txt)
objs=$(grep -Ec ' obj/\S+\.o(bj)?$' ghci-stage1-steps.tmp.txt)

echo "$steps build steps in stage 1, including $objs target-platform objects"

if [ $steps -lt 5000 -o $steps -gt 30000 -o $objs -gt 8000 ]
then
	echo 'Error: outside of expected range'
	exit 1
fi

########

# Remove from stage 2 the objects that are built in stage 1

ninja -f ghci-stage1.ninja -t inputs ghci-stage1 \
| grep -E '^obj/.+\.o(bj)?$' \
> ghci-objects-stage1.tmp.txt

# Note: The size of this list does not match the $objs count that we
# obtained above, partly because not every object filename is printed
# in the Ninja log output.

comm -23 \
	ghci-objects.txt \
	ghci-objects-stage1.tmp.txt \
> ghci-objects-stage2.tmp.txt

echo "$(wc -l < ghci-objects-stage2.tmp.txt) objects to build in stage 2"

########

echo "Splitting up stage 2 build into $split parts"

split -a 1 -n r/$split \
	--numeric-suffixes=1 \
	--additional-suffix=.txt \
	ghci-objects-stage2.tmp.txt \
	ghci-objects-part

ninja -t compdb > ghci-compdb.tmp.json

$(dirname $0)/ninja-compdb-extract.py \
	ghci-compdb.tmp.json \
	ghci-objects-part*.txt \
> ghci-stage2.ninja

########

cat << END
Generated ghci-stage1.ninja, use target "ghci-stage1"
Generated ghci-stage2.ninja, use targets "part1", "part2", ... "part$split"
END

if ! grep -q '^  command = test -s ' toolchain.ninja
then
	perl -pi \
		-e 'if (/^rule /) { $a = / (cc|cxx)$/; }' \
		-e 'if ($a) { s/^(  command) =/$1 = test -s \${out} && touch -c \${out} ||/; }' \
		toolchain.ninja

	echo 'Modified "cc" and "cxx" rules in toolchain.ninja'
fi

rm ghci-*.tmp.json ghci-*.tmp.ninja ghci-*.tmp.txt

echo 'GHCI strategy complete.'

# EOF
