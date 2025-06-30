# Multi-stage build for System Monitor service (Go)
FROM golang:1.24-alpine AS builder

WORKDIR /app

# Copy go mod files
COPY modules/sysmonitor/go.mod modules/sysmonitor/go.sum ./
RUN go mod download

# Copy source code
COPY modules/sysmonitor/ ./

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main ./cmd/main.go

# Final stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates tzdata

WORKDIR /root/

# Copy the binary from builder stage
COPY --from=builder /app/main .

# Copy config file
COPY --from=builder /app/internal/configs/config.yaml ./

# Expose port
EXPOSE 8002

# Run the binary
CMD ["./main"]
