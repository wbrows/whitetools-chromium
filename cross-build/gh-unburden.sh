#!/bin/sh
# gh-unburden.sh
#
# Script to delete unnecessary files on the GitHub runner to make more
# working space available. As this is intended to run inside a container,
# the runner's root filesystem should be mounted on /HOST/.
#

set -e

# Must run as root
test $(id -u) -eq 0

# Verify that /HOST is a mountpoint
mountpoint -q /HOST

cd /HOST

echo Before:
df -m .

# Note that /opt/hostedtoolcache/ is mounted elsewhere inside the
# container, so don't remove the directory, only its contents

rm -rf \
	opt/hostedtoolcache/* \
	usr/lib/google-cloud-sdk \
	usr/lib/jvm \
	usr/local/.ghcup \
	usr/local/julia* \
	usr/local/lib/android \
	usr/local/lib/node_modules \
	usr/local/share/chromium \
	usr/local/share/powershell \
	usr/share/dotnet \
	usr/share/miniconda \
	usr/share/swift

echo After:
df -m .

# end gh-unburden.sh
