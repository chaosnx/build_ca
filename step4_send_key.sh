#!/bin/sh

usage () {
	echo "$0 [CA section name] [username]"
	exit 1
}

if [ $# -ne 2 ]
then
	usage
fi

set -x

source config.sh

CA_NAME="$1"
USERNAME="$2"
SERVERADDR=https://subdomain.domain.com
MAILFROM=firewall@domain.com
SUBJECT=ComapnySite device access certificate



SSL_DIR="`pwd`/etc/ssl"
SSL_PRIVATE_DIR="$SSL_DIR/${CA_NAME}/private"
SSL_CERTS_DIR="$SSL_DIR/${CA_NAME}/certs"
USERS_DIR="${SSL_CERTS_DIR}/users/${USERNAME}"

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

PASSWD=$(cat ${SSL_CERTS_DIR}/users/${USERNAME}/${USERNAME}.paswd)

MAILTO=$(openssl x509 -in ${USERS_DIR}/${USERNAME}.crt -noout -subject | sed -e 's/^subject.*emailAddress=\([a-zA-Z0-9\.@\-\*]*\).*$/\1/')

BODY="instructions.html"
ATTACH="${USERS_DIR}/${USERNAME}.p12"
MAILPART=$RANDOM ## Generates Unique ID
MAILPART_BODY=$RANDOM ## Generates Unique ID
URL=`echo $RANDOM | md5`

WEBPATH="/var/www/htdocs/"
WEBFILE="certificates/${USERNAME}_$URL.html"

mkdir -p $(dirname $WEBPATH$WEBFILE)

cat $BODY | sed "s@Password@\"$PASSWD\"@g" | sed "s@URL@$SERVERADDR/$WEBFILE@g" > $WEBPATH$WEBFILE

cat $WEBPATH$WEBFILE

(                                                                               
 echo "From: $MAILFROM"                                                         
 echo "To: $MAILTO"                                                             
 echo "Subject: $SUBJECT"                                                       
 echo "MIME-Version: 1.0"                                                       
 echo "Content-Type: multipart/mixed; boundary=\"$MAILPART\""                   
 echo ""                                                                        
 echo "--$MAILPART"                                                             
 echo "Content-Type: multipart/alternative; boundary=\"$MAILPART_BODY\""        
 echo ""                                                                        
 echo "--$MAILPART_BODY"                                                        
 echo "Content-Type: text/plain; charset=ISO-8859-1"                            
 echo "You need to enable HTML option for email"                                
 echo "--$MAILPART_BODY"                                                        
 echo "Content-Type: text/html; charset=ISO-8859-1"                             
 echo "Content-Disposition: inline"                                             
 cat $BODY | sed "s@URL@$SERVERADDR/$WEBFILE@g"
 echo "--$MAILPART_BODY--"                                                      
 echo ""                                                                        
 echo "--$MAILPART"                                                             
 echo 'Content-Type: application/x-pkcs12; name="'$(basename $ATTACH)'"'        
 echo "Content-Transfer-Encoding: uuencode"                                     
 echo 'Content-Disposition: attachment; filename="'$(basename $ATTACH)'"'       
 echo ""                                                                        
 uuencode $ATTACH $(basename $ATTACH)                                           
 echo "--$MAILPART--"                                                           
) | /usr/sbin/sendmail $MAILTO
