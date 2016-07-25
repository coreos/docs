set -e

if [ $# -lt 1 ]; then
  echo 1>&2 "$0: missing target directory"
  exit 2
fi

echo 'Generating initial keys'
gpg2 --batch --gen-key aci-signing-key-batch

echo 'Generating public signing key'
gpg2 --no-default-keyring --armor \
--secret-keyring ./signing.sec --keyring ./signing.pub \
--output $1/signing-public.gpg \
--export "<support@quay.io>"

echo 'Determining private key'
PRIVATE_KEY=`gpg2 --no-default-keyring \
--secret-keyring ./signing.sec --keyring ./signing.pub \
--list-keys | tail -n 3 | head -n 1 | cut -c 13-20`

echo 'Exporting private signing key'
echo "Private key name: $PRIVATE_KEY"
gpg2 --no-default-keyring \
--secret-keyring ./signing.sec --keyring ./signing.pub --export-secret-key > $1/signing-private.gpg

echo 'Cleaning up'
rm signing.sec
rm signing.pub

echo "Emitted $1/signing-private.gpg and $1/signing-public.gpg"