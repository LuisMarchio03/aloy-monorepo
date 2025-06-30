# Multi-stage build for Core service (Go)
FROM golang:1.24-alpine AS builder

WORKDIR /app

# Copy go mod files
COPY apps/core/go.mod apps/core/go.sum ./
RUN go mod download

# Copy source code
COPY apps/core/ ./

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main ./cmd/main.go

# Final stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates tzdata

WORKDIR /root/

# Copy the binary from builder stage
COPY --from=builder /app/main .

# Expose port
EXPOSE 8080

# Run the binary
CMD ["./main"]
