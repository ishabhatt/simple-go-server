# syntax=docker/dockerfile:1

FROM golang:1.22-alpine AS builder
WORKDIR /src

# Needed for HTTPS module downloads
RUN apk add --no-cache ca-certificates

# Cache deps first
COPY go.mod ./
RUN go mod download

# Copy the rest of the source
COPY . .

# Run tests (optional but recommended)
RUN CGO_ENABLED=0 go test -buildvcs=false ./...

# Build a small static binary
RUN CGO_ENABLED=0 GOOS=linux go build -buildvcs=false -trimpath -ldflags="-s -w" -o /out/server .

# Minimal runtime image
FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=builder /out/server /server

EXPOSE 8081
USER nonroot:nonroot
ENTRYPOINT ["/server"]

