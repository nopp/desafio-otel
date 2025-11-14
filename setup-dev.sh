#!/bin/bash

echo "🚀 Desafio OTEL - Setup de Desenvolvimento"
echo "=========================================="
echo ""

# Verificar pré-requisitos
check_requirement() {
    local cmd=$1
    local name=$2
    if ! command -v $cmd &> /dev/null; then
        echo "❌ $name não encontrado. Por favor instale antes de continuar."
        return 1
    else
        echo "✅ $name encontrado"
        return 0
    fi
}

echo "🔍 Verificando pré-requisitos..."
check_requirement "docker" "Docker" && \
check_requirement "docker-compose" "Docker Compose" && \
check_requirement "git" "Git" && \
check_requirement "make" "Make"

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Alguns pré-requisitos não foram atendidos."
    echo "📚 Consulte o DEV_GUIDE.md para instruções de instalação."
    exit 1
fi

echo ""
echo "🔧 Configurando ambiente de desenvolvimento..."
echo "   • Hot reload ativado"
echo "   • Volumes para código fonte"
echo "   • Zipkin incluído"
echo ""

echo "📦 Fazendo build das imagens de desenvolvimento..."
docker-compose build

echo ""
echo "🚀 Iniciando serviços..."
docker-compose up -d

echo ""
echo "⏳ Aguardando serviços ficarem prontos..."
sleep 15

echo ""
echo "🧪 Executando teste inicial..."
response=$(curl -s -X POST http://localhost:8080 \
  -H "Content-Type: application/json" \
  -d '{"cep": "01310100"}' \
  -w "HTTPSTATUS:%{http_code}")

http_code=$(echo $response | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
body=$(echo $response | sed -E 's/HTTPSTATUS:[0-9]*$//')

if [ "$http_code" = "200" ]; then
    echo "✅ Teste inicial passou! Resposta: $body"
else
    echo "⚠️  Serviços ainda inicializando... (Status: $http_code)"
fi

echo ""
echo "✅ Ambiente de desenvolvimento configurado!"

echo ""
echo "📋 Serviços disponíveis:"
echo "   • Serviço A: http://localhost:8080"
echo "   • Serviço B: http://localhost:8081" 
echo "   • Zipkin UI: http://localhost:9411"
echo ""
echo "🔧 Comandos úteis:"
echo "   make dev-logs    # Ver logs em tempo real"
echo "   make dev-down    # Parar serviços"
echo "   make demo        # Executar testes completos"
echo "   make zipkin-ui   # Abrir Zipkin no browser"
echo ""
echo "🧪 Próximos passos:"
echo "1. Execute: make demo"
echo "2. Acesse: http://localhost:9411 (Zipkin)"
echo "3. Consulte: DEV_GUIDE.md para mais detalhes"
echo ""
echo "🎉 Ambiente de desenvolvimento pronto!"