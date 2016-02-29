#!/bin/sh

usage () {
	echo "$0 [CA section name] [username] [email addr]"
	exit 1
}

if [ $# -ne 3 ]
then
	usage
fi

set -x

CA_NAME="$1"
USERNAME="$2"
USERMAIL="$3"
SSL_SUBJ=/C=US/ST=Michigan/L=Grand Rapids/O=CompanyName/OU=CompanyUnit/CN=subdomain.domain.com





SSL_DIR="`pwd`/etc/ssl"
SSL_PRIVATE_DIR="$SSL_DIR/${CA_NAME}/private"
SSL_CERTS_DIR="$SSL_DIR/${CA_NAME}/certs"
USERS_DIR="${SSL_CERTS_DIR}/users/${USERNAME}"

if [ -d "$USERS_DIR" ]; then
    # Control will enter here if $DIRECTORY exists.
    rm -rf $USERS_DIR
fi

mkdir -p ${USERS_DIR}

# Create the Client Key and CSR
openssl genrsa -des3 -out ${USERS_DIR}/${USERNAME}.key 1024
# openssl genrsa       -out ${USERS_DIR}/${USERNAME}.key 1024
# openssl req  -config $SSL_DIR/${CA_NAME}/openssl.cnf -new -key ${USERS_DIR}/${USERNAME}.key -out ${USERS_DIR}/${USERNAME}.csr
openssl req  -config $SSL_DIR/${CA_NAME}/openssl.cnf -new -key ${USERS_DIR}/${USERNAME}.key -out ${USERS_DIR}/${USERNAME}.csr -subj "${SSL_SUBJ}"

# Sign the client certificate with our CA cert.  Unlike signing our own server cert, this is what we want to do.
#openssl x509 -req -days 1095 -in ${USERS_DIR}/${USERNAME}.csr -CA $SSL_CERTS_DIR/ca.crt -CAkey $SSL_PRIVATE_DIR/ca.key -CAserial $SSL_DIR/${CA_NAME}/serial -CAcreateserial -out ${USERS_DIR}/${USERNAME}.crt
openssl x509 -req -days 1095 -in ${USERS_DIR}/${USERNAME}.csr -CA $SSL_CERTS_DIR/ca.crt -CAkey $SSL_PRIVATE_DIR/ca.key -CAserial $SSL_DIR/${CA_NAME}/serial -CAcreateserial -out ${USERS_DIR}/${USERNAME}.crt

echo "making p12 file"
#browsers need P12s (contain key and cert)
openssl pkcs12 -export -clcerts -in ${USERS_DIR}/${USERNAME}.crt -inkey ${USERS_DIR}/${USERNAME}.key -out ${USERS_DIR}/${USERNAME}.p12

echo "made ${USERS_DIR}/${USERNAME}.p12"
