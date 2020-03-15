#!/bin/bash
set -e


echo
echo
echo "------------------------------------------------------------"
echo
echo

print_size_and_checksums () {
cat <<EOF
### \`${1}\` size and checksum

    $ stat --printf="%s bytes\n" $1
    $(stat --printf="%s bytes\n" $1)

    $ md5sum $1
    $(md5sum $1)

    $ sha256sum $1
    $(sha256sum $1)

    $ b2sum $1
    $(b2sum $1)

EOF
}

cd veracrypt/src/Main
print_size_and_checksums veracrypt
print_size_and_checksums veracrypt_nogui

cat <<EOF

------------------------------------------------------------

EOF
