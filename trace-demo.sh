#!/bin/bash

echo "🔍 Demonstração do Tracing Distribuído com OpenTelemetry + Zipkin"
echo "================================================================="
echo ""
echo "🏃 Executando várias requisições para gerar traces..."
echo ""

# Função para fazer requisições com delays para melhor visualização
make_request() {
    local cep=$1
    local description=$2
    echo "📋 $description (CEP: $cep)"
    
    curl -s -X POST http://localhost:8080 \
      -H "Content-Type: application/json" \
      -d "{\"cep\": \"$cep\"}" \
      -w "Status: %{http_code} | Tempo: %{time_total}s\n" | \
      jq . 2>/dev/null || cat
    
    echo ""
    sleep 1
}

# Testar diferentes cenários para gerar traces variados
make_request "01310100" "Teste 1: São Paulo - SP"
make_request "20040020" "Teste 2: Rio de Janeiro - RJ"  
make_request "30112000" "Teste 3: Belo Horizonte - MG"
make_request "85015040" "Teste 4: Curitiba - PR"
make_request "12345678" "Teste 5: CEP inválido (erro esperado)"
make_request "123" "Teste 6: CEP com formato incorreto (erro esperado)"

echo ""
echo "✅ Testes concluídos!"
echo ""
echo "🔍 Para visualizar os traces distribuídos:"
echo "   1. Acesse: http://localhost:9411"
echo "   2. Clique em 'Run Query' para ver os traces"
echo "   3. Clique em um trace individual para ver detalhes"
echo ""
echo "📊 O que você verá no Zipkin:"
echo "   • service-a-input: Span do Serviço A (validação)"
echo "   • call-service-b: Span da comunicação entre serviços"
echo "   • service-b-weather: Span do Serviço B (orquestração)"
echo "   • fetch-cep-info: Span da busca de CEP (ViaCEP API)"
echo "   • fetch-weather-info: Span da busca de clima (WeatherAPI)"
echo ""
echo "🕐 Cada span mostra:"
echo "   • Tempo de duração da operação"
echo "   • Atributos (CEP, cidade, temperaturas)"
echo "   • Erros (se houver)"
echo "   • Hierarquia das chamadas"