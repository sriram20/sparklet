#
# Spark Standalone Container
# Apache Spark 1.6.0
#
# Runs a super-tiny, Spark standalone cluster in a container
# Suitable for building test/development containers for spark apps
#
# Usage:
# $ docker build -t uncharted/sparklet .
# $ docker run -p 8080:8080 -it uncharted/sparklet

FROM anapsix/alpine-java:latest
MAINTAINER Sean McIntyre <smcintyre@uncharted.software>

# spark web admin port
EXPOSE 8080

# spark debugging port
EXPOSE 9999

WORKDIR /opt

RUN \
  # update packages
  apk update && \
  # grab curl and ssh
  apk add openssh vim curl procps && \
  curl http://apache.mirror.gtcomm.net/spark/spark-1.6.0/spark-1.6.0-bin-hadoop2.6.tgz > spark.tgz && \
  # generate a keypair and authorize it
  mkdir -p /root/.ssh && \
  ssh-keygen -f /root/.ssh/id_rsa -N "" && \
  cat /root/.ssh/id_rsa.pub > /root/.ssh/authorized_keys && \
  # extract spark
  tar -xzf spark.tgz && \
  # cleanup
  rm spark.tgz

# s6 overlay
RUN \
 curl -LS https://github.com/just-containers/s6-overlay/releases/download/v1.17.1.1/s6-overlay-amd64.tar.gz -o /tmp/s6-overlay.tar.gz && \
 tar xvfz /tmp/s6-overlay.tar.gz -C / && \
 rm -f /tmp/s6-overlay.tar.gz

# upload init scripts
ADD services/spark-master-run /etc/services.d/spark-master/run
ADD services/spark-slave-run /etc/services.d/spark-slave/run

# upload permission fix script
ADD fix-attrs/spark /etc/fix-attrs.d/spark

ENV PATH /opt/spark-1.6.0-bin-hadoop2.6/bin:$PATH
ENV JAVA_HOME /opt/jdk

ENTRYPOINT [ "/init" ]

CMD ["spark-shell"]
