# Multi-stage build for Task Sync service (Go)
FROM golang:1.24-alpine AS builder

WORKDIR /app

# Copy go mod files
COPY modules/tasksync/go.mod modules/tasksync/go.sum ./
RUN go mod download

# Copy source code
COPY modules/tasksync/ ./

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main ./cmd/main.go

# Final stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates tzdata

WORKDIR /root/

# Copy the binary from builder stage
COPY --from=builder /app/main .

# Run the binary
CMD ["./main"]
