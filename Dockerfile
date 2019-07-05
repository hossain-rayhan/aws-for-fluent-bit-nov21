FROM golang:1.12 as go-build
RUN go get github.com/aws/amazon-kinesis-firehose-for-fluent-bit
WORKDIR /go/src/github.com/aws/amazon-kinesis-firehose-for-fluent-bit
RUN make release
RUN go get github.com/aws/amazon-cloudwatch-logs-for-fluent-bit
WORKDIR /go/src/github.com/aws/amazon-cloudwatch-logs-for-fluent-bit
RUN make release

FROM amazonlinux:latest as builder

# Fluent Bit version
ENV FLB_MAJOR 1
ENV FLB_MINOR 1
ENV FLB_PATCH 3
ENV FLB_VERSION 1.1.3

ENV FLB_TARBALL http://github.com/fluent/fluent-bit/archive/v$FLB_VERSION.zip
RUN mkdir -p /fluent-bit/bin /fluent-bit/etc /fluent-bit/log /tmp/fluent-bit-master/

RUN yum upgrade -y && \
    yum install -y  \
      build-essential \
      cmake3 \
      gcc \
      gcc-c++ \
      make \
      wget \
      unzip \
      git \
      go \
      libssl1.0-dev \
      libasl-dev \
      libsasl2-dev \
      pkg-config \
      libsystemd-dev \
      zlib1g-dev \
      ca-certificates \
      flex \
      bison \
    && alternatives --install /usr/local/bin/cmake cmake /usr/bin/cmake3 20 \
      --slave /usr/local/bin/ctest ctest /usr/bin/ctest3 \
      --slave /usr/local/bin/cpack cpack /usr/bin/cpack3 \
      --slave /usr/local/bin/ccmake ccmake /usr/bin/ccmake3 \
      --family cmake \
    && wget -O "/tmp/fluent-bit-${FLB_VERSION}.zip" ${FLB_TARBALL} \
    && cd /tmp && unzip "fluent-bit-$FLB_VERSION.zip" \
    && cd "fluent-bit-$FLB_VERSION"/build/ \
    && rm -rf /tmp/fluent-bit-$FLB_VERSION/build/*

WORKDIR /tmp/fluent-bit-$FLB_VERSION/build/
RUN cmake -DFLB_DEBUG=On \
          -DFLB_TRACE=Off \
          -DFLB_JEMALLOC=On \
          -DFLB_TLS=On \
          -DFLB_SHARED_LIB=Off \
          -DFLB_EXAMPLES=Off \
          -DFLB_HTTP_SERVER=On \
          -DFLB_IN_SYSTEMD=On \
          -DFLB_OUT_KAFKA=On ..

RUN make -j $(getconf _NPROCESSORS_ONLN)
RUN install bin/fluent-bit /fluent-bit/bin/

# Configuration files
COPY fluent-bit.conf \
     /fluent-bit/etc/


FROM amazonlinux:latest
COPY --from=builder /fluent-bit /fluent-bit
COPY --from=go-build /go/src/github.com/aws/amazon-kinesis-firehose-for-fluent-bit/bin/firehose.so /fluent-bit/firehose.so
COPY --from=go-build /go/src/github.com/aws/amazon-cloudwatch-logs-for-fluent-bit/bin/cloudwatch.so /fluent-bit/cloudwatch.so
RUN mkdir -p /fluent-bit/licenses/fluent-bit
RUN mkdir -p /fluent-bit/licenses/firehose
RUN mkdir -p /fluent-bit/licenses/cloudwatch
COPY THIRD-PARTY /fluent-bit/licenses/fluent-bit/
COPY --from=go-build /go/src/github.com/aws/amazon-kinesis-firehose-for-fluent-bit/THIRD-PARTY \
    /go/src/github.com/aws/amazon-kinesis-firehose-for-fluent-bit/LICENSE \
    /fluent-bit/licenses/firehose/
COPY --from=go-build /go/src/github.com/aws/amazon-cloudwatch-logs-for-fluent-bit/THIRD-PARTY \
    /go/src/github.com/aws/amazon-cloudwatch-logs-for-fluent-bit/LICENSE \
    /fluent-bit/licenses/cloudwatch/

# Optional Metrics endpoint
EXPOSE 2020

# Entry point
CMD ["/fluent-bit/bin/fluent-bit", "-e", "/fluent-bit/firehose.so", "-e", "/fluent-bit/cloudwatch.so", "-c", "/fluent-bit/etc/fluent-bit.conf"]