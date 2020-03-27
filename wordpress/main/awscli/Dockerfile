ARG PERL_VERSION

ARG IMAGE
ARG VERSION

FROM perl:${PERL_VERSION} AS builder

COPY /main/awscli/aws/ /tmp/tpl/

ARG S3_ACCESS_KEY
ARG S3_SECRET_KEY
ARG S3_REGION

RUN mkdir /aws \
 && cat /tmp/tpl/config.ini | \
    S3_REGION="${S3_REGION}" \
    perl -p \
    -e 's/\Q{{S3_REGION}}\E/$ENV{S3_REGION}/g;' \
    > /aws/config \
 && cat /tmp/tpl/credentials.ini | \
    S3_ACCESS_KEY="${S3_ACCESS_KEY}" \
    S3_SECRET_KEY="${S3_SECRET_KEY}" \
    perl -p \
    -e 's/\Q{{S3_ACCESS_KEY}}\E/$ENV{S3_ACCESS_KEY}/g;' \
    -e 's/\Q{{S3_SECRET_KEY}}\E/$ENV{S3_SECRET_KEY}/g;' \
    > /aws/credentials

FROM $IMAGE:$VERSION

COPY --from=builder /aws/ /root/.aws/