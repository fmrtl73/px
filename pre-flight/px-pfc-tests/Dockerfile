FROM debian:latest
MAINTAINER alex.diaz@portworx.com
#RUN apt-get update -y && apt-get install -y wget curl

ADD pre_flight_checks.sh /
RUN chmod +x /pre_flight_checks.sh
COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]


