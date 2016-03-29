#!/bin/bash
#BASED ON catatnight/docker-postfix

if [ "$maildomain" = "" ] ; then
  echo "maildomain environment variable not set. Please set maildomain."
  exit 1
fi

if [ "$smtp_user" = "" ] ; then
  echo "smtp_user environment variable not set. Please set smtp_user."
  echo "smtp_user=user1:passwd1,user2:passwd2...."
  exit 1
fi

postconf -e myhostname=$maildomain


#ISSO SERVE PARA CRIAR OS USUARIOS A PARTIR DA ENV DE USER, QUEBRADA POR USER:PASS,USER:PASS...
#SASL SUPPORT FOR CLIENTS
echo $smtp_user | tr , \\n | while IFS=':' read -r _user _pwd; do
  echo $_pwd | saslpasswd2 -p -c -u $maildomain $_user
done
chown postfix.sasl /etc/sasldb2


############
# Enable TLS
############
if [[ -n "$(find /etc/postfix/certs -iname *.crt)" && -n "$(find /etc/postfix/certs -iname *.key)" ]]; then
  # /etc/postfix/main.cf
  postconf -e smtpd_tls_cert_file=$(find /etc/postfix/certs -iname *.crt)
  postconf -e smtpd_tls_key_file=$(find /etc/postfix/certs -iname *.key)
  chmod 400 /etc/postfix/certs/*.*
  # /etc/postfix/master.cf
  postconf -M submission/inet="submission   inet   n   -   n   -   -   smtpd"
  postconf -P "submission/inet/syslog_name=postfix/submission"
  postconf -P "submission/inet/smtpd_tls_security_level=encrypt"
  postconf -P "submission/inet/smtpd_sasl_auth_enable=yes"
  postconf -P "submission/inet/milter_macro_daemon_name=ORIGINATING"
  postconf -P "submission/inet/smtpd_recipient_restrictions=permit_sasl_authenticated,reject_unauth_destination"
fi



############
# opendkim
############
if [ "$OPENDKIM_ENABLED" = "true" ] ; then
  postconf -e milter_protocol=2
  postconf -e milter_default_action=accept
  postconf -e smtpd_milters=inet:localhost:12301
  postconf -e non_smtpd_milters=inet:localhost:12301

  if [[ -z "$(find /etc/opendkim/domainkeys -iname *.private)" ]]; then
    exit 0
  fi

  if ! grep -q "$maildomain" /etc/opendkim/TrustedHosts ; then
  cat >> /etc/opendkim/TrustedHosts <<EOF
*.$maildomain
EOF
  fi

  if ! grep -q "$maildomain" /etc/opendkim/KeyTable ; then
    cat >> /etc/opendkim/KeyTable <<EOF
mail._domainkey.$maildomain $maildomain:mail:$(find /etc/opendkim/domainkeys -iname *.private)
EOF
  fi

  if ! grep -q "$maildomain" /etc/opendkim/SigningTable ; then
  cat >> /etc/opendkim/SigningTable <<EOF
*@$maildomain mail._domainkey.$maildomain
EOF
  fi

  chown opendkim:opendkim $(find /etc/opendkim/domainkeys -iname *.private)
  chmod 400 $(find /etc/opendkim/domainkeys -iname *.private)

fi
