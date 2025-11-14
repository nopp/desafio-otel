#!/bin/bash

echo "🚀 Testando os serviços com OpenTelemetry + Zipkin..."
echo "📊 Interface do Zipkin disponível em: http://localhost:9411"
echo ""

echo ""
echo "📋 Teste 1: CEP válido (29902555)"
curl -X POST http://localhost:8080 \
  -H "Content-Type: application/json" \
  -d '{"cep": "29902555"}' \
  -w "\nStatus: %{http_code}\n"

echo ""
echo "📋 Teste 2: CEP inválido - formato incorreto (123)"
curl -X POST http://localhost:8080 \
  -H "Content-Type: application/json" \
  -d '{"cep": "123"}' \
  -w "\nStatus: %{http_code}\n"

echo ""
echo "📋 Teste 3: CEP inválido - não numérico (abcdefgh)"
curl -X POST http://localhost:8080 \
  -H "Content-Type: application/json" \
  -d '{"cep": "abcdefgh"}' \
  -w "\nStatus: %{http_code}\n"

echo ""
echo "📋 Teste 4: CEP não encontrado (99999999)"
curl -X POST http://localhost:8080 \
  -H "Content-Type: application/json" \
  -d '{"cep": "99999999"}' \
  -w "\nStatus: %{http_code}\n"

echo ""
echo "📋 Teste 5: Método GET (deve falhar)"
curl -X GET http://localhost:8080 \
  -w "\nStatus: %{http_code}\n"

echo ""
echo "📋 Teste 6: Testando Serviço B diretamente"
curl "http://localhost:8081/weather?cep=01310100" \
  -w "\nStatus: %{http_code}\n"