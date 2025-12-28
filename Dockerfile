# syntax=docker/dockerfile:1

FROM golang:1.22-alpine AS build
WORKDIR /app

# Cache deps first
COPY go.* ./
RUN go mod download

# Copy the rest of the source
COPY . .

RUN go test ./...

# Build a small static binary
RUN CGO_ENABLED=0 GOOS=linux go build -o server .

# Minimal runtime image
FROM gcr.io/distroless/base-debian12
WORKDIR /
COPY --from=build /app/server /server

ARG VCS_REF=""
ARG BUILD_DATE=""
LABEL org.opencontainers.image.revision=$VCS_REF \
      org.opencontainers.image.created=$BUILD_DATE \
      org.opencontainers.image.source="https://github.com/ishabhatt/simple-go-server" \
	  org.opencontainers.image.title="simple-go-server" \
	  org.opencontainers.image.description="Minimal Go HTTP server with posts API"

EXPOSE 8081
USER nonroot:nonroot
ENTRYPOINT ["/server"]

