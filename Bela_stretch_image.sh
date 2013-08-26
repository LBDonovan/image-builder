#!/bin/bash -e

time=$(date +%Y-%m-%d)
DIR="$PWD"

./RootStock-NG.sh -c  bela-debian-stretch-v4.9

debian_stretch_bela="debian-stretch-bela-armhf-${time}"

archive="xz -z -8 -v"

beaglebone="--dtb beaglebone --bbb-old-bootloader-in-emmc --hostname beaglebone"

bb_blank_flasher="--dtb bbb-blank-eeprom --bbb-old-bootloader-in-emmc \
--hostname beaglebone"

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

###oemflasher images: (also single partition)
base_rootfs="${debian_stretch_Bela}" ; blend="Bela" ; extract_base_rootfs

options="--img-2gb bone-\${base_rootfs} ${beaglebone}" ; generate_img

###archive *.tar
base_rootfs="${debian_stretch_Bela}" ; blend="Bela" ; archive_base_rootfs

__EOF__

chmod +x ${DIR}/deploy/gift_wrap_final_images.sh
