# Simple Couchbase Server instance
#
# Install Couchbase Server Community Edition (version as per CB_VERSION below)
#
# VERSION 0.9.4
#
# Forked for BGCH CB by Luke Bond <luke@yld.io>

FROM ubuntu
MAINTAINER Brian Shumate, brian@couchbase.com

ENV CB_VERSION 2.5.1
ENV CB_BASE_URL https://s3-eu-west-1.amazonaws.com/connectedboiler-couchbase
ENV CB_EDITION enterprise
ENV CB_PACKAGE couchbase-server-${CB_EDITION}_${CB_VERSION}_x86_64.deb
ENV CB_DOWNLOAD_URL ${CB_BASE_URL}/${CB_PACKAGE}
ENV CB_LOCAL_PATH /tmp/${CB_PACKAGE}

ENV CB_INIT_DATA_PATH /opt/couchbase/var/lib/couchbase/data
ENV CB_INIT_INDEX_PATH /opt/couchbase/var/lib/couchbase/data
ENV CB_INIT_USERNAME Administrator
ENV CB_INIT_PASSWORD password
ENV CB_INIT_BUCKET_NAME bgch-cb-api
ENV CB_INIT_BUCKET_ENABLEFLUSH 0
ENV DEBIAN_FRONTEND noninteractive


# Add Universe (for libssl0.9.8 dependency), update & install packages
RUN sed -i.bak 's/main$/main universe/' /etc/apt/sources.list

RUN apt-get -y update && \
  apt-get -y install curl wget librtmp0 libssl0.9.8 lsb-release python jq

# Download Couchbase Server package to /tmp & install
RUN wget $CB_DOWNLOAD_URL -O $CB_LOCAL_PATH
RUN dpkg -i $CB_LOCAL_PATH

ADD etcdctl /usr/bin/
ADD run.sh .
CMD ["./run.sh"]
