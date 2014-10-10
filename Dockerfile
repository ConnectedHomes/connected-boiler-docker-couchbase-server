# Simple Couchbase Server instance
#
# Install Couchbase Server Community Edition (version as per CB_VERSION below)
#
# VERSION 0.9.4
#
# Forked for BGCH CB by Luke Bond <luke@yld.io>

FROM ubuntu
MAINTAINER Brian Shumate, brian@couchbase.com

ENV CB_VERSION 3.0.0
ENV CB_BASE_URL http://packages.couchbase.com/releases/${CB_VERSION}
ENV CB_EDITION enterprise
ENV CB_PACKAGE couchbase-server-${CB_EDITION}_${CB_VERSION}-ubuntu12.04_amd64.deb
ENV CB_DOWNLOAD_URL ${CB_BASE_URL}/${CB_PACKAGE}
ENV CB_LOCAL_PATH /tmp/${CB_PACKAGE}

# Limits
RUN sed -i.bak '/\# End of file/ i\\# Following 4 lines added by docker-couchbase-server' /etc/security/limits.conf
RUN sed -i.bak '/\# End of file/ i\\*                hard    memlock          unlimited' /etc/security/limits.conf
RUN sed -i.bak '/\# End of file/ i\\*                soft    memlock         unlimited\n' /etc/security/limits.conf
RUN sed -i.bak '/\# End of file/ i\\*                hard    nofile          65536' /etc/security/limits.conf
RUN sed -i.bak '/\# End of file/ i\\*                soft    nofile          65536\n' /etc/security/limits.conf
RUN sed -i.bak '/\# end of pam-auth-update config/ i\\# Following line was added by docker-couchbase-server' /etc/pam.d/common-session
RUN sed -i.bak '/\# end of pam-auth-update config/ i\session	required        pam_limits.so\n' /etc/pam.d/common-session

# Locale and supporting utility commands
RUN locale-gen en_US en_US.UTF-8
RUN echo 'root:couchbase' | chpasswd
RUN mkdir -p /var/run/sshd

# Add Universe (for libssl0.9.8 dependency), update & install packages
RUN sed -i.bak 's/main$/main universe/' /etc/apt/sources.list
RUN apt-get -y update && apt-get -y install librtmp0 libssl0.9.8 lsb-release openssh-server

# Download Couchbase Server package to /tmp & install
RUN wget $CB_DOWNLOAD_URL -O $CB_LOCAL_PATH
RUN dpkg -i $CB_LOCAL_PATH

# Open the OpenSSH server and Couchbase Server ports
EXPOSE 22 4369 8091 8092 11209 11210 11211

ADD run.sh .
CMD ["./run.sh"]
