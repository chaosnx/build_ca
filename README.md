# build_ca
build scripts to create client side authentication

This is a collection and complenation and improvement to what I have found on the internet and my basic setup on an OpenBSD Server.

I used Nginx because I cannot use OpenBSD's httpd engine due to the lack of support in client auth in the libTLS.

this folows a 4 step path. 
1. Create the Root CA
2. Create new server Keys (Self Sign if you dare)
3. Create new keys for your clients
4. Send keys via Email.

First edit the scripts to put your information in.

# 1. Create the Root CA

his will take you through the steps to make the Root CA for your sights

it builds all files in a folder relitive to the your current path.

'''sh
./step1_new_ca.sh sitename
'''

# 2. Create new server Keys

this will create a server key and un-encript it so you dont need to type it when the server restarts.

'''sh
./step2_new_server_key.sh sitename
'''

# 3. Create new keys for your clients

this is where you create a key for your clients then make a cert to install in there devices. Thus to allow acess to the server.

'''sh
./step3_new_client.sh sitename username useremailaddr
'''

# 4. Send keys via Email.

this script crafts a email to send to the device. it took me a bit to figure this one out so that the email client can actualy show the link correctly.

'''sh
./step3_new_client.sh sitename username useremailaddr
'''

# Configs

## OpenSSL config

see the example openssl.cnf that is list. it's was based from [MIT's OpenSSL.cnf](http://web.mit.edu/crypto/openssl.cnf)

## Nginx Config

fill in the IP Address you use on the server's interface you plan on using.
'''
http {
    server {
      
        access_log  /var/log/nginx/access.log main;
        error_log   /var/log/nginx/error.log info;
        index       index.html;
        listen      xxx.xxx.xxx.xxx:443 ssl;
        root        /var/www/htdocs/subdomain.domain.com;
        server_name subdomain.domain.com;

        # SSL certs
        ssl on;
        ssl_certificate        /etc/ssl/CA_section_name/certs/server.crt;
        ssl_certificate_key    /etc/ssl/CA_section_name/private/server.key;
        ssl_client_certificate /etc/ssl/CA_section_name/certs/ca.crt;
        ssl_crl                /etc/ssl/CA_section_name/private/ca.crl;
        ssl_verify_client      on;
    }
}
'''

## SMTPD

This is the setup to send the mail through gmail.com smtp server so i dont get flaged as spam

'''
#	$OpenBSD: smtpd.conf,v 1.7 2014/03/12 18:21:34 tedu Exp $

# This is the smtpd server system-wide configuration file.
# See smtpd.conf(5) for more information.

# To accept external mail, replace with: listen on all
#
listen on lo0

table aliases db:/etc/mail/aliases.db


## the file holding the gmail username and password 
## created with "makemap /etc/mail/secrets"
table secrets db:/etc/mail/secrets.db

# Uncomment the following to accept external mail for domain "example.org"
#
# accept from any for domain "example.org" alias <aliases> deliver to mbox
accept for local alias <aliases> deliver to mbox
#accept from local for any relay


## outgoing mail is accepted from localhost only and relayed through 
## Google's gmail using TLS authentication on port 587 ro 465. The user and password 
## from the map "secrets"' file is used.
## This rule is for local users _only_ to send mail through gmail. No open relays!
accept from local for any relay via secure+auth://label@smtp.gmail.com:587 auth <secrets>
'''

add this line to your rc.conf.local
'''sh
echo "smtpd_flags=\"\"" >> /etc/rc.conf.local
'''

edit the /etc/mail/secrets file
'''sh
# use this command to build the file
# on FreeBSD /usr/local/libexec/opensmtpd/makemap secrets
# on OpenBSD /usr/sbin/makemap secrets
label username@gmail.com:password
'''




## Refrences:

RYNOP's Blog [HOWTO: Client side certificate auth with Nginx NOVEMBER 26, 2012 BY RYNOP] (https://rynop.wordpress.com/2012/11/26/howto-client-side-certificate-auth-with-nginx/)

Drumcoder's Blog [Client Side Certificates for Web Apps October 19, 2011](http://drumcoder.co.uk/blog/2011/oct/19/client-side-certificates-web-apps/)

both these seem to ref:

http://wiki.nginx.org/HttpSslModule

http://blog.nategood.com/client-side-certificate-authentication-in-ngi

http://it.toolbox.com/blogs/securitymonkey/howto-securing-a-website-with-client-ssl-certificates-11500