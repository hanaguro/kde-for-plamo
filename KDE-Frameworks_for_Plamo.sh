#!/bin/bash

VERS=5.113.0
SITE=https://download.kde.org/stable/frameworks/5.113/

while read -r col1 col2 _; do
        if [[ "${col1:0:1}" != "#" ]]; then
                array+=("$col2")
        fi
done < frameworks-${VERS}.md5

set -e

for i in "${array[@]}"
do
        basename=$(echo "$i" | sed "s/-${VERS}.*//")
        if [ -d $basename ]; then
                continue
        fi
        mkdir ${basename}
        cd ${basename}
        wget ${SITE}$i
        tar xvf $i
        version=$(echo "$i" | sed 's/\(.*\)\.tar\.xz/\1/')
        make_PlamoBuild.py ${version} -u ${SITE}$i
        sed -i 's/OPT_CONFIG="-DCMAKE_BUILD_TYPE=Release"/OPT_CONFIG="-DCMAKE_BUILD_TYPE=Release -DKDE_INSTALL_LIBDIR=lib"/' PlamoBuild.${version}
        ./PlamoBuild.${version}
        updatepkg -f *.tzst
        mv *.tzst ..
        cd ..
done

exit 0
