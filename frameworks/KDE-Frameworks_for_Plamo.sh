#!/bin/bash

VERS=6.32.0
SITE=https://download.kde.org/stable/frameworks/${VERS%.0}/
SITE2=https://download.kde.org/stable/frameworks/${VERS%.0}/portingAids/

while read -r col1 col2 _; do
        if [[ "${col1:0:1}" != "#" ]]; then
                array+=("$col2")
        fi
done < frameworks-${VERS}.md5

for i in "${array[@]}"
do
        basename=$(echo "$i" | sed "s/-${VERS}.*//")
	basename=$(echo "${basename}" | sed "s/-/_/g")
	echo "install $VERS"
	if [ -f /var/log/packages/$basename ]; then
		pkg_ver=$(grep "PACKAGE NAME:" /var/log/packages/${basename} | awk -F' ' '{ print $3 }'| awk -F'-' '{ print $2 }')
		echo "allready installed $pkg_ver"
		if [[ "$VERS" == "$pkg_ver" ]] || printf '%s\n%s\n' "$VERS" "$pkg_ver" | sort -V -C; then
			echo "skip build $basename"
			continue
		fi
	fi
		
        mkdir -p ${basename}
        cd ${basename}
        wget -N ${SITE}$i
        if [ $? -ne 0 ]; then
                wget ${SITE2}$i
                if [ $? -ne 0 ]; then
                        exit 1
                fi
        fi
        set -e
        tar xvf $i
        version=$(echo "$i" | sed 's/\(.*\)\.tar\.xz/\1/')
        yes | make_PlamoBuild.py ${version} -u ${SITE}$i
	if [ ${basename} == "kimageformats" ];then
        	sed -i 's/OPT_CONFIG="-DCMAKE_BUILD_TYPE=Release"/OPT_CONFIG="-DCMAKE_BUILD_TYPE=Release -DKDE_INSTALL_LIBDIR=lib -DCMAKE_SKIP_INSTALL_RPATH=ON -DBUILD_TESTING=OFF -DKIMAGEFORMATS_HEIF=ON -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_CXX_STANDARD=20"/' PlamoBuild.${version}
	else
        	sed -i 's/OPT_CONFIG="-DCMAKE_BUILD_TYPE=Release"/OPT_CONFIG="-DCMAKE_BUILD_TYPE=Release -DKDE_INSTALL_LIBDIR=lib -DCMAKE_SKIP_INSTALL_RPATH=ON -DBUILD_TESTING=OFF -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_CXX_STANDARD=20"/' PlamoBuild.${version}
	fi
        ./PlamoBuild.${version}
        updatepkg -f *.tzst
        mv *.tzst ..
        set +e
        cd ..
done

exit 0
