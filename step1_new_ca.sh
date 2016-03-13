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
SSL_SUBJ=/C=US/ST=Michigan/L=Grand Rapids/O=CompanyName/OU=CompanyUnit/CN=rootCA.subdomain.domain.com

if [ -z "$CA_PASSWORD" ]; then
    stty -echo
    while true; do
        echo -n Password:
        read -s CA_PASSWORD
        echo
        echo -n Password Verify:
        read -s CA_PASSWORD_V
        echo
        if [ "$CA_PASSWORD" = "$CA_PASSWORD_V" ] && [ ! -z "$CA_PASSWORD" ]
        then
            break
        else
            echo "Try Again"
        fi
    done
    export CA_PASSWORD=$CA_PASSWORD
    stty echo
fi
SSL_DIR="`pwd`/etc/ssl"
SSL_PRIVATE_DIR="$SSL_DIR/${CA_NAME}/private"
SSL_CERTS_DIR="$SSL_DIR/${CA_NAME}/certs"

rm -rf $SSL_DIR/${CA_NAME}/

mkdir -p ${SSL_PRIVATE_DIR}
mkdir -p ${SSL_CERTS_DIR}

touch $SSL_DIR/${CA_NAME}/index.txt
touch $SSL_DIR/${CA_NAME}/crlnumber

# You need to create the file crlnumber manually if you get an error: No such file. Modern OpenSSL versions require this.
echo 01 > $SSL_DIR/${CA_NAME}/crlnumber

sed "s@PATH@$SSL_DIR/${CA_NAME}@g" ./openssl.cnf > $SSL_DIR/${CA_NAME}/openssl.cnf

# Create the CA Key and Certificate for signing Client Certs (good for 3 yrs)
openssl genrsa -out $SSL_PRIVATE_DIR/ca.key -passout env:CA_PASSWORD -des3 4096 
# openssl genrsa -out $SSL_PRIVATE_DIR/ca.key 4096

openssl rsa -passin env:CA_PASSWORD -pubout -in $SSL_PRIVATE_DIR/ca.key -out $SSL_PRIVATE_DIR/ca.pub

#openssl req -config $SSL_DIR/${CA_NAME}/openssl.cnf -new -x509 -days 1095 -key $SSL_PRIVATE_DIR/ca.key -out $SSL_CERTS_DIR/ca.crt
openssl req -passin env:CA_PASSWORD -config $SSL_DIR/${CA_NAME}/openssl.cnf -new -x509 -days 1095 -key $SSL_PRIVATE_DIR/ca.key -out $SSL_CERTS_DIR/ca.crt -subj "${SSL_SUBJ}" 


# Create a Certificate Revocation list for removing 'user certificates.'
#openssl ca -config $SSL_DIR/${CA_NAME}/openssl.cnf -name ${CA_NAME} -gencrl -keyfile $SSL_PRIVATE_DIR/ca.key -cert $SSL_CERTS_DIR/ca.crt -out $SSL_PRIVATE_DIR/ca.crl -crldays 1095
openssl ca -passin env:CA_PASSWORD -config $SSL_DIR/${CA_NAME}/openssl.cnf -gencrl -keyfile $SSL_PRIVATE_DIR/ca.key -cert $SSL_CERTS_DIR/ca.crt -out $SSL_PRIVATE_DIR/ca.crl -crldays 1095

set +xv # echo off
