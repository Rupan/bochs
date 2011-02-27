#!/bin/bash
#
# tarball.sh
#
# Copyright © 2004, 2007-2010 Guillem Jover <guillem@debian.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#

set -e
set -u

action=$1
shift

get_version()
{
  local d=$1

  eval $(grep '^VERSION=' $d/configure.in | sed -e 's/\.\(cvs\|svn\)//' )

  echo $VERSION
}

echo "-> getting the source."
case "$action" in
  snapshot)
    echo " -> making a svn snapshot."

    snapshot_dir="bochs-snapshot"

    if [ -d $snapshot_dir ]; then
      svn up $snapshot_dir
    else
      SVNROOT="https://bochs.svn.sourceforge.net/svnroot/bochs"
      svn co $SVNROOT/trunk/bochs $snapshot_dir
    fi

    version="$(get_version $snapshot_dir)+$(date +%Y%m%d)"
    ;;
  tarball)
    echo " -> unpacking upstream tarball."

    upstream_dir="bochs-tarball"
    upstream_tarball=$1

    mkdir $upstream_dir
    cd $upstream_dir
    tar xzf ../$upstream_tarball --strip 1
    cd ..

    version=$(get_version $upstream_dir)
    ;;
esac

tarball=bochs_$version.orig.tar.gz
tree=bochs-$version

echo "-> filling the working tree."
case "$action" in
  snapshot)
    svn export $snapshot_dir $tree
    ;;
  tarball)
    mv $upstream_dir $tree
    ;;
esac

if ! [ -e $tree/bochs.h ]
then
  echo "error: no bochs tree available."
  exit 1
fi

echo "-> fixing permissions."
find $tree -type f -name '*.cc' -o -name '*.h' -o -name '*.inc' \
  -o -name 'Makefile.in' -o -name 'patch.*' -o -name '*.diff' \
  -o -name 'todo' -o -name '*.txt' \
  -o -name '*.def' -o -name '*.rc' -o -name '*.rc.in' -o -name '*.r' \
  -o -name '*.data' -o -name '*.ico' -o -name '*.xpm' \
  | xargs chmod -x

echo "-> cleaning tree."
# Clean non-free stuff
rm -f $tree/bios/BIOS*
rm -f $tree/bios/VGABIOS*
rm -f $tree/bios/acpi-dsdt.hex
rm -f $tree/patches/beos-gui-fabo.capture-filter

echo "-> creating new tarball."
tar czf $tarball $tree

echo "-> cleaning directory tree."
rm -rf $tree

