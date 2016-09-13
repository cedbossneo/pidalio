#!/usr/bin/env bash
set -e

checksum()
{
	md5sum $1 | awk '{print $1}'
}

for UTIL in ceph rbd ceph-rbdnamer rados ceph-disk; do

    if [ ! -e /opt/bin/$UTIL ] || [ "$(checksum /opt/bin/$UTIL)" != "$(checksum /opt/pidalio/kube/kubelet/scripts/ceph/$UTIL)" ]; then
    	echo "Installing $UTIL to /opt/bin"
    	cp -pf /opt/pidalio/kube/kubelet/scripts/ceph/$UTIL /opt/bin
    fi

done

if [ ! -e /etc/udev/rules.d/50-rbd.rules ] || [ "$(checksum /etc/udev/rules.d/50-rbd.rules)" != "$(checksum /opt/pidalio/kube/kubelet/scripts/ceph/50-rbd.rules)" ]; then
    echo "Installing 50-rbd.rules to /etc/udev/rules.d/"
    cp -pf /opt/pidalio/kube/kubelet/scripts/ceph/50-rbd.rules /etc/udev/rules.d/
fi
