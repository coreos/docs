#!/bin/bash -e

usage() {
        echo "Usage: $0 %number_of_coreos_nodes%"
}

if [ "$1" == "" ]; then
        echo "Cluster size is empty"
        usage
        exit 1
fi

if ! [[ $1 =~ ^[0-9]+$ ]]; then
        echo "'$1' is not a number"
        usage
        exit 1
fi

LIBVIRT_PATH=/var/lib/libvirt/images/coreos
USER_DATA_TEMPLATE=$LIBVIRT_PATH/user_data
ETCD_DISCOVERY=$(curl -s "https://discovery.etcd.io/new?size=$1")
CHANNEL=stable
RELEASE=current
RAM=1024
CPUs=1
IMG_NAME="coreos_${CHANNEL}_${RELEASE}_qemu_image.img"

if [ ! -d $LIBVIRT_PATH ]; then
        mkdir -p $LIBVIRT_PATH || (echo "Can not create $LIBVIRT_PATH directory" && exit 1)
fi

if [ ! -f $USER_DATA_TEMPLATE ]; then
        echo "$USER_DATA_TEMPLATE template doesn't exist"
        exit 1
fi

for SEQ in $(seq 1 $1); do
        COREOS_HOSTNAME="coreos$SEQ"

        if [ ! -d $LIBVIRT_PATH/$COREOS_HOSTNAME/openstack/latest ]; then
                mkdir -p $LIBVIRT_PATH/$COREOS_HOSTNAME/openstack/latest || (echo "Can not create $LIBVIRT_PATH/$COREOS_HOSTNAME/openstack/latest directory" && exit 1)
        fi

        if [ ! -f $LIBVIRT_PATH/$IMG_NAME ]; then
                wget http://${CHANNEL}.release.core-os.net/amd64-usr/${RELEASE}/coreos_production_qemu_image.img.bz2 -O - | bzcat > $LIBVIRT_PATH/$IMG_NAME || (rm -f $LIBVIRT_PATH/$IMG_NAME && echo "Failed to download image" && exit 1)
        fi

        if [ ! -f $LIBVIRT_PATH/$COREOS_HOSTNAME.qcow2 ]; then
                qemu-img create -f qcow2 -b $LIBVIRT_PATH/$IMG_NAME $LIBVIRT_PATH/$COREOS_HOSTNAME.qcow2
        fi

        sed "s#%HOSTNAME%#$COREOS_HOSTNAME#g;s#%DISCOVERY%#$ETCD_DISCOVERY#g" $USER_DATA_TEMPLATE > $LIBVIRT_PATH/$COREOS_HOSTNAME/openstack/latest/user_data

        virt-install --connect qemu:///system \
                     --import \
                     --name $COREOS_HOSTNAME \
                     --ram $RAM \
                     --vcpus $CPUs \
                     --os-type=linux \
                     --os-variant=virtio26 \
                     --disk path=$LIBVIRT_PATH/$COREOS_HOSTNAME.qcow2,format=qcow2,bus=virtio \
                     --filesystem $LIBVIRT_PATH/$COREOS_HOSTNAME/,config-2,type=mount,mode=squash \
                     --vnc \
                     --noautoconsole
done
