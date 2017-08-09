#!/bin/bash -e

usage() {
  echo "
Usage: $0 [options]
Options:
    -c|--channel        CHANNEL
                        channel name (stable/beta/alpha)           [default: stable]
    -r|--release        RELEASE
                        CoreOS release                             [default: current]
    -s|--size           CLUSTER_SIZE
                        Amount of virtual machines in a cluster.   [default: 1]
    -p|--pub-key        PUBLIC_KEY
                        Path to public key. Private key path will
                        be detected automatically.                 [default: ~/.ssh/id_rsa.pub]
    -i|--config         CLOUD_CONFIG
                        Path to cloud-config.                      [default: ./user_data]
    -m|--ram            RAM
                        Amount of memory in megabytes for each VM. [default: 512]
    -u|--cpu            CPUs
                        Amount of CPUs for each VM.                [default: 1]
    -v|--verbose        Make verbose
    -h|--help           This help message

This script is a wrapper around libvirt for starting a cluster of CoreOS virtual
machines.
"
}

print_red() {
  echo -e "\e[91m$1\e[0m"
}

print_green() {
  echo -e "\e[92m$1\e[0m"
}

check_cmd() {
  which "$1" >/dev/null || { print_red "'$1' command is not available, please install it first, then try again" && exit 1; }
}

handle_channel_release() {
  if [ -z "$1" ]; then
    print_green "$OS_NAME doesn't use channel"
  else
    : ${CHANNEL:=$1}
    if [ -n "$OPTVAL_CHANNEL" ]; then
      CHANNEL=$OPTVAL_CHANNEL
    else
      print_green "Using default $CHANNEL channel for $OS_NAME"
    fi
  fi
  if [ -z "$2" ]; then
    print_green "$OS_NAME doesn't use release"
  else
    : ${RELEASE:=$2}
    if [ -n "$OPTVAL_RELEASE" ]; then
      RELEASE=$OPTVAL_RELEASE
    else
      print_green "Using default $RELEASE release for $OS_NAME"
    fi
  fi
}

check_cmd wget
check_cmd virsh
check_cmd virt-install
check_cmd qemu-img
check_cmd genisoimage
check_cmd xzcat
check_cmd bzcat
check_cmd cut
check_cmd sed

USER_ID=${SUDO_UID:-$(id -u)}
USER=$(getent passwd "${USER_ID}" | cut -d: -f1)
HOME=$(getent passwd "${USER_ID}" | cut -d: -f6)

trap usage EXIT

while [ $# -ge 1 ]; do
  case "$1" in
    -c|--channel)
      OPTVAL_CHANNEL="$2"
      shift 2 ;;
    -r|--release)
      OPTVAL_RELEASE="$2"
      shift 2 ;;
    -s|--cluster-size)
      OPTVAL_CLUSTER_SIZE="$2"
      shift 2 ;;
    -p|--pub-key)
      OPTVAL_PUB_KEY="$2"
      shift 2 ;;
    -i|--config)
      OPTVAL_CLOUD_CONFIG="$2"
      shift 2 ;;
    -m|--ram)
      OPTVAL_RAM="$2"
      shift 2 ;;
    -u|--cpu)
      OPTVAL_CPU="$2"
      shift 2 ;;
    -v|--verbose)
      set -x
      shift ;;
    -h|-help|--help)
      usage
      trap - EXIT
      trap
      exit ;;
    *)
      break ;;
  esac
done

trap - EXIT
trap

OS_NAME="coreos"

export LIBVIRT_DEFAULT_URI=qemu:///system
virsh nodeinfo > /dev/null 2>&1 || { print_red "Failed to connect to the libvirt socket"; exit 1; }
virsh list --all --name | grep -q "^${OS_NAME}1$" && { print_red "'${OS_NAME}1' VM already exists"; exit 1; }

: ${CLUSTER_SIZE:=1}
if [ -n "$OPTVAL_CLUSTER_SIZE" ]; then
  if ! [[ "$OPTVAL_CLUSTER_SIZE" =~ ^[0-9]+$ ]]; then
    print_red "'$OPTVAL_CLUSTER_SIZE' is not a number"
    usage
    exit 1
  fi
  CLUSTER_SIZE=$OPTVAL_CLUSTER_SIZE
fi

: ${INIT_PUB_KEY:="$HOME/.ssh/id_rsa.pub"}
if [ -n "$OPTVAL_PUB_KEY" ]; then
  INIT_PUB_KEY=$OPTVAL_PUB_KEY
fi

if [[ -z "$INIT_PUB_KEY" || ! -f "$INIT_PUB_KEY" ]]; then
  print_red "SSH public key path is not valid or not specified"
  if [ -n "$HOME" ]; then
    PUB_KEY_PATH="$HOME/.ssh/id_rsa.pub"
  else
    print_red "Can not determine home directory for SSH pub key path"
    exit 1
  fi

  print_green "Will use default path to SSH public key: $PUB_KEY_PATH"
  if [ ! -f "$PUB_KEY_PATH" ]; then
    print_red "Path $PUB_KEY_PATH doesn't exist"
    PRIV_KEY_PATH=$(echo "${PUB_KEY_PATH}" | sed 's#.pub##')
    if [ -f "$PRIV_KEY_PATH" ]; then
      print_green "Found private key, generating public key..."
      if [ -n "$SUDO_UID" ]; then
        sudo -u "$USER" ssh-keygen -y -f "$PRIV_KEY_PATH" | sudo -u "$USER" tee "${PUB_KEY_PATH}" > /dev/null
      else
        ssh-keygen -y -f "$PRIV_KEY_PATH" > "${PUB_KEY_PATH}"
      fi
    else
      print_green "Generating private and public keys..."
      if [ -n "$SUDO_UID" ]; then
        sudo -u "$USER" ssh-keygen -t rsa -N "" -f "$PRIV_KEY_PATH"
      else
        ssh-keygen -t rsa -N "" -f "$PRIV_KEY_PATH"
      fi
    fi
  fi
else
  PUB_KEY_PATH="$INIT_PUB_KEY"
  print_green "Will use following path to SSH public key: $PUB_KEY_PATH"
fi

OPENSTACK_DIR="openstack/latest"
PUB_KEY=$(cat "${PUB_KEY_PATH}")
PRIV_KEY_PATH=$(echo ${PUB_KEY_PATH} | sed 's#.pub##')
CDIR=$(cd `dirname $0` && pwd)
IMG_PATH="${HOME}/libvirt_images/${OS_NAME}"
RANDOM_PASS=$(openssl rand -base64 12)

: ${USER_DATA_TEMPLATE:="${CDIR}/user_data"}
if [ -n "$OPTVAL_CLOUD_CONFIG" ]; then
  if [ -f "$OPTVAL_CLOUD_CONFIG" ]; then
    USER_DATA_TEMPLATE=$OPTVAL_CLOUD_CONFIG
  else
    print_red "Custom cloud-config specified, but it is not available"
    print_red "Will use default cloud-config path (${USER_DATA_TEMPLATE})"
  fi
fi

ETCD_DISCOVERY=$(curl -s "https://discovery.etcd.io/new?size=$CLUSTER_SIZE")

handle_channel_release stable current

: ${RAM:=512}
if [ -n "$OPTVAL_RAM" ]; then
  if ! [[ "$OPTVAL_RAM" =~ ^[0-9]+$ ]]; then
    print_red "'$OPTVAL_RAM' is not a valid amount of RAM"
    usage
    exit 1
  fi
  RAM=$OPTVAL_RAM
fi

: ${CPUs:=1}
if [ -n "$OPTVAL_CPU" ]; then
  if ! [[ "$OPTVAL_CPU" =~ ^[0-9]+$ ]]; then
    print_red "'$OPTVAL_CPU' is not a valid amount of CPUs"
    usage
    exit 1
  fi
  CPUs=$OPTVAL_CPU
fi

IMG_NAME="coreos_${CHANNEL}_${RELEASE}_qemu_image.img"
IMG_URL="https://${CHANNEL}.release.core-os.net/amd64-usr/${RELEASE}/coreos_production_qemu_image.img.bz2"
SIG_URL="https://${CHANNEL}.release.core-os.net/amd64-usr/${RELEASE}/coreos_production_qemu_image.img.bz2.sig"
GPG_PUB_KEY="https://coreos.com/security/image-signing-key/CoreOS_Image_Signing_Key.asc"
GPG_PUB_KEY_ID="48F9B96A2E16137F"

set +e
if gpg --version > /dev/null 2>&1; then
  GPG=true
  if ! gpg --list-sigs $GPG_PUB_KEY_ID > /dev/null; then
    wget -q -O - $GPG_PUB_KEY | gpg --import --keyid-format LONG || { GPG=false && print_red "Warning: can not import GPG public key"; }
  fi
else
  GPG=false
  print_red "Warning: please install GPG to verify CoreOS images' signatures"
fi
set -e

IMG_EXTENSION=""
if [[ "${IMG_URL}" =~ \.([a-z0-9]+)$ ]]; then
  IMG_EXTENSION=${BASH_REMATCH[1]}
fi

case "${IMG_EXTENSION}" in
  bz2)
    DECOMPRESS="bzcat";;
  xz)
    DECOMPRESS="xzcat";;
  *)
    DECOMPRESS="cat";;
esac

if [ ! -d "$IMG_PATH" ]; then
  mkdir -p "$IMG_PATH" || { print_red "Can not create $IMG_PATH directory" && exit 1; }
fi

if [ ! -f "$USER_DATA_TEMPLATE" ]; then
  print_red "$USER_DATA_TEMPLATE template doesn't exist"
  exit 1
fi

for SEQ in $(seq 1 $CLUSTER_SIZE); do
  VM_HOSTNAME="${OS_NAME}${SEQ}"
  if [ -z $FIRST_HOST ]; then
    FIRST_HOST=$VM_HOSTNAME
  fi

  if [ ! -d "$IMG_PATH/$VM_HOSTNAME/$OPENSTACK_DIR" ]; then
    mkdir -p "$IMG_PATH/$VM_HOSTNAME/$OPENSTACK_DIR" || { print_red "Can not create $IMG_PATH/$VM_HOSTNAME/$OPENSTACK_DIR directory" && exit 1; }
    sed "s#%PUB_KEY%#$PUB_KEY#g;\
         s#%HOSTNAME%#$VM_HOSTNAME#g;\
         s#%DISCOVERY%#$ETCD_DISCOVERY#g;\
         s#%RANDOM_PASS%#$RANDOM_PASS#g;\
         s#%FIRST_HOST%#$FIRST_HOST#g" "$USER_DATA_TEMPLATE" > "$IMG_PATH/$VM_HOSTNAME/$OPENSTACK_DIR/user_data"
    if selinuxenabled 2>/dev/null; then
      # We use ISO configdrive to avoid complicated SELinux conditions
      genisoimage -input-charset utf-8 -R -V config-2 -o "$IMG_PATH/$VM_HOSTNAME/configdrive.iso" "$IMG_PATH/$VM_HOSTNAME" || { print_red "Failed to create ISO image"; exit 1; }
      echo -e "#!/bin/sh\ngenisoimage -input-charset utf-8 -R -V config-2 -o \"$IMG_PATH/$VM_HOSTNAME/configdrive.iso\" \"$IMG_PATH/$VM_HOSTNAME\"" > "$IMG_PATH/$VM_HOSTNAME/rebuild_iso.sh"
      chmod +x "$IMG_PATH/$VM_HOSTNAME/rebuild_iso.sh"
      CONFIG_DRIVE="--disk path=\"$IMG_PATH/$VM_HOSTNAME/configdrive.iso\",device=cdrom"
    else
      CONFIG_DRIVE="--filesystem \"$IMG_PATH/$VM_HOSTNAME/\",config-2,type=mount,mode=squash"
    fi
  fi

  virsh pool-info $OS_NAME > /dev/null 2>&1 || virsh pool-create-as $OS_NAME dir --target "$IMG_PATH" || { print_red "Can not create $OS_NAME pool at $IMG_PATH target" && exit 1; }
  # Make this pool persistent
  (virsh pool-dumpxml $OS_NAME | virsh pool-define /dev/stdin)
  virsh pool-start $OS_NAME > /dev/null 2>&1 || true

  if [ ! -f "$IMG_PATH/$IMG_NAME" ]; then
    trap 'rm -f "$IMG_PATH/$IMG_NAME"' INT TERM EXIT
    if [ $GPG ]; then
      eval "gpg --enable-special-filenames \
                --verify \
                --batch \
                <(wget -q -O - \"$SIG_URL\")\
                <(wget -O - \"$IMG_URL\" | tee >($DECOMPRESS > \"$IMG_PATH/$IMG_NAME\"))" || { rm -f "$IMG_PATH/$IMG_NAME" && print_red "Failed to download and verify the image" && exit 1; }
    else
      eval "wget \"$IMG_URL\" -O - | $DECOMPRESS > \"$IMG_PATH/$IMG_NAME\"" || { rm -f "$IMG_PATH/$IMG_NAME" && print_red "Failed to download the image" && exit 1; }
    fi
    trap - INT TERM EXIT
    trap
  fi

  if [ ! -f "$IMG_PATH/${VM_HOSTNAME}.qcow2" ]; then
    qemu-img create -f qcow2 -b "$IMG_PATH/$IMG_NAME" "$IMG_PATH/${VM_HOSTNAME}.qcow2" || \
      { print_red "Failed to create ${VM_HOSTNAME}.qcow2 volume image" && exit 1; }
    virsh pool-refresh $OS_NAME
  fi

  virt-install \
    --connect $LIBVIRT_DEFAULT_URI \
    --import \
    --name $VM_HOSTNAME \
    --ram $RAM \
    --vcpus $CPUs \
    --os-type=linux \
    --os-variant=virtio26 \
    --disk path="$IMG_PATH/$VM_HOSTNAME.qcow2",format=qcow2,bus=virtio \
    $CONFIG_DRIVE \
    --vnc \
    --noautoconsole
done

print_green "Use following command to connect to your cluster: 'ssh -i \"$PRIV_KEY_PATH\" core@$FIRST_HOST'"
