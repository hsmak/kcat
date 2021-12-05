FROM eclipse-temurin:11-jdk-alpine as jdk11

#Scala
ENV SCALA_VERSION=2.13.7 \
    SCALA_HOME=/opt/scala/scala2_13

RUN apk add --no-cache --virtual=.build-dependencies wget ca-certificates && \
    apk add --no-cache bash && \
    cd "/tmp" && \
    wget "https://downloads.typesafe.com/scala/${SCALA_VERSION}/scala-${SCALA_VERSION}.tgz" && \
    tar xzf "scala-${SCALA_VERSION}.tgz" && \
    mkdir -p "${SCALA_HOME}" && \
    mv "/tmp/scala-${SCALA_VERSION}/"*  "${SCALA_HOME}" && \
    ln -s "${SCALA_HOME}/bin/"* "/usr/bin/" && \
    apk del .build-dependencies && \
    rm -rf "/tmp/"*

RUN echo Verifying install ...  && \
    echo scala --version && \
    scala --version

FROM alpine:3.14

#JDK
COPY --from=jdk11 /opt/java /opt/java
ENV JAVA_HOME=/opt/java/openjdk \
    PATH=$PATH:/opt/java/openjdk/bin
RUN echo Verifying install ... && \
    echo javac --version && \
    javac --version  && \
    echo java --version && \
    java --version

#Scala
COPY --from=jdk11 /opt/scala /opt/scala

ENV SCALA_HOME=/opt/scala/scala2_13 \
    PATH=$PATH:/opt/scala/scala2_13/bin

#RUN echo Verifying install ... && echo scala --version && scala --version


#KCat
COPY . /usr/src/kcat

ENV BUILD_DEPS make gcc g++ cmake curl pkgconfig python3 perl bsd-compat-headers zlib-dev zstd-dev zstd-libs lz4-dev openssl-dev curl-dev

ENV RUN_DEPS bash jq libcurl lz4-libs zstd-libs ca-certificates

# Kerberos requires a default realm to be set in krb5.conf, which we can't
# do for obvious reasons. So skip it for now.
#ENV BUILD_DEPS_EXTRA cyrus-sasl-dev
#ENV RUN_DEPS_EXTRA libsasl heimdal-libs krb5

RUN echo Installing ; \
  apk add --no-cache --virtual .dev_pkgs $BUILD_DEPS $BUILD_DEPS_EXTRA && \
  apk add --no-cache $RUN_DEPS $RUN_DEPS_EXTRA && \
  echo Building && \
  cd /usr/src/kcat && \
  rm -rf tmp-bootstrap && \
  echo "Source versions:" && \
  grep ^github_download ./bootstrap.sh && \
  ./bootstrap.sh --no-install-deps --no-enable-static && \
  mv kcat /usr/bin/ && \
  echo Cleaning up && \
  cd / && \
  rm -rf /usr/src/kcat && \
  apk del .dev_pkgs && \
  rm -rf /var/cache/apk/*

RUN kcat -V


ENTRYPOINT [""]
