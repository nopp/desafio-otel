#!/bin/bash

echo "🚀 Iniciando Demonstração Completa do Tracing Distribuído"
echo "========================================================="
echo ""

# Verificar se o Zipkin está rodando
echo "🔍 Verificando se o Zipkin está disponível..."
if curl -s http://localhost:9411/health >/dev/null; then
    echo "✅ Zipkin está rodando em http://localhost:9411"
    ZIPKIN_AVAILABLE=true
else
    echo "⚠️  Zipkin não está disponível. Rodando com tracing local."
    echo "   Para usar Zipkin: docker run -d -p 9411:9411 openzipkin/zipkin:3.4"
    ZIPKIN_AVAILABLE=false
fi

echo ""
echo "🛑 Parando processos anteriores..."
pkill -f "./main" 2>/dev/null || true
sleep 2

echo "🚀 Iniciando serviços com OpenTelemetry..."
if [ "$ZIPKIN_AVAILABLE" = true ]; then
    ZIPKIN_ENDPOINT=http://localhost:9411/api/v2/spans ./main &
else
    ./main &
fi

SERVICE_PID=$!
echo "   Processo iniciado com PID: $SERVICE_PID"
sleep 3

echo ""
echo "🧪 Executando testes de tracing..."
echo ""

# Função para fazer requisições
test_request() {
    local cep=$1
    local desc=$2
    echo "📋 $desc"
    
    response=$(curl -s -X POST http://localhost:8080 \
      -H "Content-Type: application/json" \
      -d "{\"cep\": \"$cep\"}" \
      -w "HTTPSTATUS:%{http_code};TIME:%{time_total}")
    
    http_code=$(echo $response | grep -o "HTTPSTATUS:[0-9]*" | cut -d: -f2)
    time_total=$(echo $response | grep -o "TIME:[0-9.]*" | cut -d: -f2)
    body=$(echo $response | sed -E 's/HTTPSTATUS:[0-9]*;TIME:[0-9.]*$//')
    
    echo "   Status: $http_code | Tempo: ${time_total}s"
    if [ "$http_code" = "200" ]; then
        echo "   Resposta: $(echo $body | jq -c . 2>/dev/null || echo $body)"
    else
        echo "   Erro: $body"
    fi
    echo ""
    sleep 1
}

# Executar testes variados para gerar traces interessantes
test_request "01310100" "Teste 1: São Paulo - SP (sucesso)"
test_request "20040020" "Teste 2: Rio de Janeiro - RJ (sucesso)"
test_request "99999999" "Teste 3: CEP inexistente (erro 404)"
test_request "123" "Teste 4: CEP inválido (erro 422)"

echo "✅ Testes concluídos!"
echo ""

if [ "$ZIPKIN_AVAILABLE" = true ]; then
    echo "🔍 Visualizar traces no Zipkin:"
    echo "   1. Acesse: http://localhost:9411"
    echo "   2. Clique em 'Run Query'"
    echo "   3. Explore os traces gerados"
    echo ""
    echo "📊 Spans que você verá:"
    echo "   • service-a-input: Validação no Serviço A"
    echo "   • call-service-b: Comunicação A → B"
    echo "   • service-b-weather: Orquestração no Serviço B"  
    echo "   • fetch-cep-info: Consulta ViaCEP API"
    echo "   • fetch-weather-info: Consulta WeatherAPI"
else
    echo "📊 Tracing está ativo mas sem backend visual."
    echo "   Para ver traces graficamente, inicie o Zipkin:"
    echo "   docker run -d -p 9411:9411 openzipkin/zipkin:3.4"
fi

echo ""
echo "🛑 Para parar os serviços: kill $SERVICE_PID"