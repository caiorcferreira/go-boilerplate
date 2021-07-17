FROM golang:1.16.5 AS build-env

WORKDIR /opt

COPY . /opt
RUN make build

# ------------------------------- #
FROM gcr.io/distroless/static:nonroot

ARG binary_name

WORKDIR /opt
COPY --from=build-env /opt/$binary_name ./app
USER 65532:65532

ENTRYPOINT ["/opt/app"]
