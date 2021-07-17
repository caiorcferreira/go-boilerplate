FROM golang:1.16.5-alpine AS build-env

WORKDIR /opt

RUN apk update && apk add make

COPY . /opt
RUN make

FROM alpine:3.14.0

ARG binary_name

WORKDIR /opt
COPY --from=build-env /opt/${binary_name} ./app
RUN chmod +x ./app

ENTRYPOINT ["/opt/app"]
