#!/bin/sh

usage () {
	echo "$0 [CA section name]"
	exit 1
}

if [ $# -ne 1 ]
then
	usage
fi

# set -x #echo on
set +x #echo off
set +v #echo off

CA_NAME="$1"
SSL_SUBJ=/C=US/ST=Michigan/L=Grand Rapids/O=CompanyName/OU=CompanyUnit/CN=subdomain.domain.com

stty -echo
while true; do
    echo -n CA Password:
    read -s CA_PASSWORD
    echo
    echo -n CA Password Verify:
    read -s CA_PASSWORD_V
    echo
    if [ "$CA_PASSWORD" = "$CA_PASSWORD_V" ] && [ ! -z "$CA_PASSWORD" ]
    then
        break
    else
        echo "Try Again"
    fi
done
stty echo

stty -echo
while true; do
    echo -n Server Password:
    read -s Server_PASSWORD
    echo
    echo -n Server Password Verify:
    read -s Server_PASSWORD_V
    echo
    if [ "$Server_PASSWORD" = "$Server_PASSWORD_V" ] && [ ! -z "$Server_PASSWORD" ]
    then
        break
    else
        echo "Try Again"
    fi
done
stty echo

SSL_DIR="`pwd`/etc/ssl"
SSL_PRIVATE_DIR="$SSL_DIR/${CA_NAME}/private"
SSL_CERTS_DIR="$SSL_DIR/${CA_NAME}/certs"

mkdir -p ${SSL_PRIVATE_DIR}
mkdir -p ${SSL_CERTS_DIR}

# Create the Server Key, CSR, and Certificate
openssl genrsa -des3 -out $SSL_PRIVATE_DIR/server.key -passout pass:$Server_PASSWORD 1024


# Generate a Certificate request of our key
#openssl req -config $SSL_DIR/${CA_NAME}/openssl.cnf -new -key $SSL_PRIVATE_DIR/server.key -out $SSL_PRIVATE_DIR/server.csr
openssl req -passin pass:$Server_PASSWORD -config $SSL_DIR/${CA_NAME}/openssl.cnf -new -key $SSL_PRIVATE_DIR/server.key -out $SSL_PRIVATE_DIR/server.csr -subj "${SSL_SUBJ}"



# Remove the necessity of entering a passphrase for starting up nginx with SSL using the private key
cp $SSL_PRIVATE_DIR/server.key $SSL_PRIVATE_DIR/server.key.org
openssl rsa -passin pass:$Server_PASSWORD -in $SSL_PRIVATE_DIR/server.key.org -out $SSL_PRIVATE_DIR/server.key

# We're self signing our own server cert here.  This is a no-no in production.
openssl x509 -req -passin pass:$CA_PASSWORD -days 1095 -in $SSL_PRIVATE_DIR/server.csr -CA $SSL_CERTS_DIR/ca.crt -CAkey $SSL_PRIVATE_DIR/ca.key -set_serial 02 -out $SSL_CERTS_DIR/server.crt
