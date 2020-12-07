#!/bin/bash

# Discover public and private IP for this instance
PUBLIC_IPV4="$(curl -4 icanhazip.com)"
PRIVATE_IPV4="$(ip addr show eth0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)"

PORT=${PORT:-3478}
ALT_PORT=${PORT:-3479}

TLS_PORT=${TLS:-5349}
TLS_ALT_PORT=${PORT:-5350}

MIN_PORT=${MIN_PORT:-49152}
MAX_PORT=${MAX_PORT:-65535}

TURNSERVER_CONFIG=/etc/coturn/turnserver.conf

cat <<EOF > ${TURNSERVER_CONFIG}.default
# https://github.com/coturn/coturn/blob/master/examples/etc/coturn.conf
listening-port=${PORT}
#listening-ip=${PUBLIC_IPV4}
#relay-ip=${PUBLIC_IPV4}
#listening-ip=0.0.0.0
#relay-ip=0.0.0.0
#external-ip=${PUBLIC_IPV4}
#min-port=${MIN_PORT}
#max-port=${MAX_PORT}
fingerprint
lt-cred-mech
total-quota=100
#bps-capacity=6400000
#max-bps=640000
stale-nonce
cipher-list="ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:ECDH+3DES:DH+3DES:RSA+AES:RSA+3DES:!ADH:!AECDH:!MD5"
no-loopback-peers
no-multicast-peers

EOF


if [ -n "${JSON_CONFIG}" ]; then
  echo "${JSON_CONFIG}" | jq -r '.config[]' >> ${TURNSERVER_CONFIG}.default
fi

if [ -n "$STATIC_AUTH_SECRET" ]; then
  echo "use-auth-secret" >> ${TURNSERVER_CONFIG}.default
  echo "static-auth-secret=${STATIC_AUTH_SECRET}" >> ${TURNSERVER_CONFIG}.default
  echo "realm=${REALM}" >> ${TURNSERVER_CONFIG}.default
fi

if [ -n "$LETSENCRYPT" ]; then
  cp /certs/${REALM}.crt /etc/coturn/turnserver_cert.pem
  cp /certs/${REALM}.key /etc/coturn/turnserver_pkey.pem

  cat <<EOT >> ${TURNSERVER_CONFIG}.default
tls-listening-port=${TLS_PORT}
alt-tls-listening-port=${TLS_ALT_PORT}
cert=/etc/coturn/turnserver_cert.pem
pkey=/etc/coturn/turnserver_pkey.pem
EOT

fi

envsubst < ${TURNSERVER_CONFIG}.default > ${TURNSERVER_CONFIG}

exec /usr/bin/turnserver -v
