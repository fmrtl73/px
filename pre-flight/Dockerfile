FROM ubuntu:latest
MAINTAINER sathya@portworx.com
RUN apt-get update -y && apt-get install -y wget curl

ADD scripts /opt/pwx/bin/
RUN chmod +x /opt/pwx/bin/*

ENTRYPOINT [/opt/pwx/bin/run-pre-flight]
