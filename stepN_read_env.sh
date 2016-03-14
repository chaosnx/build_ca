#!/bin/sh

usage () {
	echo "$0 [CA section name] [username]"
	exit 1
}

if [ $# -ne 1 ] && [ $# -ne 2 ]
then
	usage
fi

CA_NAME="$1"

SSL_DIR="`pwd`/etc/ssl"
SSL_PRIVATE_DIR="$SSL_DIR/${CA_NAME}/private"
SSL_CERTS_DIR="$SSL_DIR/${CA_NAME}/certs"


if [ -e "$SSL_PRIVATE_DIR/ca.passwds" ]; then
    if [ -z "$CA_PASSWORD" ]
    then
        for LINE in `openssl base64 -d -in $SSL_PRIVATE_DIR/ca.passwds | openssl rsautl -decrypt -inkey $SSL_PRIVATE_DIR/ca.key -passin env:CA_PASSWORD | grep -v ^#`; do
            eval "export ${LINE}"
        done
    else
        for LINE in `openssl base64 -d -in $SSL_PRIVATE_DIR/ca.passwds | openssl rsautl -decrypt -inkey $SSL_PRIVATE_DIR/ca.key | grep -v ^#`; do
            eval "export ${LINE}"
        done
    fi
    unset LINE
fi

if [ -e "$SSL_PRIVATE_DIR/server.passwd" ]; then
    for LINE in `openssl base64 -d -in $SSL_PRIVATE_DIR/server.passwd | openssl rsautl -decrypt -inkey $SSL_PRIVATE_DIR/ca.key -passin env:CA_PASSWORD | grep -v ^#`; do
        eval "export ${LINE}"
    done
    unset LINE
fi

if [ -z "$2" ]
then
    USERNAME="$2"
    USERS_DIR="${SSL_CERTS_DIR}/users/${USERNAME}"

    if [ -e "${USERS_DIR}/${USERNAME}.key.passwd" ]; then
        for LINE in `openssl base64 -d -in  ${USERS_DIR}/${USERNAME}.key.passwd | openssl rsautl -decrypt -inkey $SSL_PRIVATE_DIR/ca.key -passin env:CA_PASSWORD | grep -v ^#`; do
            eval "export ${LINE}"
        done
        unset LINE
    fi

    if [ -e "${USERS_DIR}/${USERNAME}.p12.passwd" ]; then
        for LINE in `openssl base64 -d -in  ${USERS_DIR}/${USERNAME}.p12.passwd | openssl rsautl -decrypt -inkey $SSL_PRIVATE_DIR/ca.key -passin env:CA_PASSWORD | grep -v ^#`; do
            eval "export ${LINE}"
        done
        unset LINE
    fi
fi