#!/bin/bash -e

time=$(date +%Y-%m-%d)
DIR="$PWD"

echo "~~ BUILDING ROOTFS ~~"
./RootStock-NG.sh -c bela-debian-stretch-v4.4

debian_stretch_bela="debian-stretch-bela-armhf-${time}"

archive="xz -z -8 -v"

cat > ${DIR}/deploy/gift_wrap_final_images.sh <<-__EOF__
#!/bin/bash

archive_base_rootfs () {
        if [ -d ./\${base_rootfs} ] ; then
                rm -rf \${base_rootfs} || true
        fi
        if [ -f \${base_rootfs}.tar ] ; then
                ${archive} \${base_rootfs}.tar && sha256sum \${base_rootfs}.tar.xz > \${base_rootfs}.tar.xz.sha256sum &
        fi
}

extract_base_rootfs () {
        if [ -d ./\${base_rootfs} ] ; then
                rm -rf \${base_rootfs} || true
        fi

        if [ -f \${base_rootfs}.tar.xz ] ; then
                tar xf \${base_rootfs}.tar.xz
        else
                tar xf \${base_rootfs}.tar
        fi
}

archive_img () {
	#prevent xz warning for 'Cannot set the file group: Operation not permitted'
	sudo chown \${UID}:\${GROUPS} \${wfile}.img
        if [ -f \${wfile}.img ] ; then
                if [ ! -f \${wfile}.bmap ] ; then
                        if [ -f /usr/bin/bmaptool ] ; then
                                bmaptool create -o \${wfile}.bmap \${wfile}.img
                        fi
                fi
                ${archive} \${wfile}.img && sha256sum \${wfile}.img.xz > \${wfile}.img.xz.sha256sum &
        fi
}

generate_img () {
        cd \${base_rootfs}/
        sudo ./setup_sdcard.sh \${options}
        mv *.img ../
        mv *.job.txt ../
        cd ..
}

echo "||||||||||| EXTRACTING ROOTFS ||||||||||||||"
###console images: (also single partition)
base_rootfs="${debian_stretch_bela}" ; blend="console" ; extract_base_rootfs

echo "||||||||||| GENERATING IMG ||||||||||||||"
options="--img-2gb bone-\${base_rootfs} --dtb beaglebone --boot_label BEAGLEBONE --enable-systemd --hostname beaglebone" ; generate_img

###archive *.tar
blend="console"
#wfile="bone-${debian_stretch_bela}-2gb" ; archive_img
__EOF__

chmod +x ${DIR}/deploy/gift_wrap_final_images.sh

cd ${DIR}/deploy
sudo ./gift_wrap_final_images.sh
