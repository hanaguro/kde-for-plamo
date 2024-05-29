#!/bin/bash

VERS=5.115.0
SITE=https://download.kde.org/stable/frameworks/5.115/
SITE2=https://download.kde.org/stable/frameworks/5.115/portingAids/

while read -r col1 col2 _; do
        if [[ "${col1:0:1}" != "#" ]]; then
                array+=("$col2")
        fi
done < frameworks-${VERS}.md5

for i in "${array[@]}"
do
        basename=$(echo "$i" | sed "s/-${VERS}.*//")
        if [ -d $basename ]; then
                continue
        fi
        mkdir ${basename}
        cd ${basename}
        wget ${SITE}$i
        if [ $? -ne 0 ]; then
                wget ${SITE2}$i
                if [ $? -ne 0 ]; then
                        exit 1
                fi
        fi
        set -e
        tar xvf $i
        version=$(echo "$i" | sed 's/\(.*\)\.tar\.xz/\1/')
        make_PlamoBuild.py ${version} -u ${SITE}$i
        sed -i 's/OPT_CONFIG="-DCMAKE_BUILD_TYPE=Release"/OPT_CONFIG="-DCMAKE_BUILD_TYPE=Release -DKDE_INSTALL_LIBDIR=lib"/' PlamoBuild.${version}
        ./PlamoBuild.${version}
        updatepkg -f *.tzst
        mv *.tzst ..
        set +e
        cd ..
done

exit 0
