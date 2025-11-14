FROM golang:1.25.1-alpine AS dev

# Instalar ferramentas de desenvolvimento
RUN apk add --no-cache git ca-certificates tzdata wget curl

# Instalar Air para hot reload
RUN go install github.com/air-verse/air@latest

WORKDIR /app

# Copiar arquivos de configuração Go
COPY go.mod go.sum ./
RUN go mod download

# Expor portas
EXPOSE 8080 8081

# Comando padrão para desenvolvimento
CMD ["air", "-c", ".air.toml"]