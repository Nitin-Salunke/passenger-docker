FROM phusion/baseimage:0.11
MAINTAINER Phusion <info@phusion.nl>

ENV OPENSSL_FIPS_MODULE openssl-fips-2.0.16
ENV OPEN_SSL_CORE openssl-1.0.2o
RUN apt-get update && apt-get install -y vim git wget sudo curl checkinstall
ADD . /pd_build
RUN /pd_build/install.sh
CMD ["/sbin/my_init"]
EXPOSE 80 443
