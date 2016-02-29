#!/bin/sh

usage () {
	echo "$0 [CA section name]"
	exit 1
}

if [ $# -ne 1 ]
then
	usage
fi

set -x

CA_NAME="$1"
SSL_SUBJ=/C=US/ST=Michigan/L=Grand Rapids/O=CompanyName/OU=CompanyUnit/CN=subdomain.domain.com




SSL_DIR="`pwd`/etc/ssl"
SSL_PRIVATE_DIR="$SSL_DIR/${CA_NAME}/private"
SSL_CERTS_DIR="$SSL_DIR/${CA_NAME}/certs"

mkdir -p ${SSL_PRIVATE_DIR}
mkdir -p ${SSL_CERTS_DIR}

# Create the Server Key, CSR, and Certificate
openssl genrsa -des3 -out $SSL_PRIVATE_DIR/server.key 1024


# Generate a Certificate request of our key
#openssl req -config $SSL_DIR/${CA_NAME}/openssl.cnf -new -key $SSL_PRIVATE_DIR/server.key -out $SSL_PRIVATE_DIR/server.csr
openssl req -config $SSL_DIR/${CA_NAME}/openssl.cnf -new -key $SSL_PRIVATE_DIR/server.key -out $SSL_PRIVATE_DIR/server.csr -subj "${SSL_SUBJ}"



# Remove the necessity of entering a passphrase for starting up nginx with SSL using the private key
cp $SSL_PRIVATE_DIR/server.key $SSL_PRIVATE_DIR/server.key.org
openssl rsa -in $SSL_PRIVATE_DIR/server.key.org -out $SSL_PRIVATE_DIR/server.key

# We're self signing our own server cert here.  This is a no-no in production.
openssl x509 -req -days 1095 -in $SSL_PRIVATE_DIR/server.csr -CA $SSL_CERTS_DIR/ca.crt -CAkey $SSL_PRIVATE_DIR/ca.key -set_serial 02 -out $SSL_CERTS_DIR/server.crt
