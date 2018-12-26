FROM gymnae/alpine-base:latest
LABEL maintainer="docker@grundstil.de" \
      tag="coturn"

RUN apk add --no-cache bash coturn@community curl gettext jq


ADD coturn.sh /coturn.sh
RUN chmod u+x /coturn.sh

EXPOSE 3389 3389/udp 53 53/udp 8080 80 8080/udp 3478 3479 3479/udp 3478/udp 443 443/udp 5349 5349/udp  

CMD /coturn.sh
