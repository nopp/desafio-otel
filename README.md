# Desafio OTEL - Serviços de CEP e Clima

Este projeto implementa dois serviços em Go:

- **Serviço A**: Responsável pela validação de input de CEP
- **Serviço B**: Responsável pela orquestração e busca de temperaturas

## Arquitetura

```
Cliente → Serviço A (validação) → Serviço B (orquestração) → APIs externas
```

## Serviços

### Serviço A (Porta 8080)
- **Endpoint**: `POST /`
- **Função**: Recebe e valida CEPs, encaminha para o Serviço B
- **Input**: `{"cep": "29902555"}`

#### Respostas:
- **200**: Sucesso (repassa resposta do Serviço B)
- **422**: CEP inválido - `invalid zipcode`
- **405**: Método não permitido

### Serviço B (Porta 8081)  
- **Endpoint**: `GET /weather?cep=<cep>`
- **Função**: Busca localização por CEP e temperaturas da cidade

#### Respostas:
- **200**: `{"city": "São Paulo", "temp_C": 28.5, "temp_F": 83.3, "temp_K": 301.65}`
- **404**: CEP não encontrado - `can not find zipcode`
- **422**: CEP inválido - `invalid zipcode`

## Como executar

### Desenvolvimento Local
```bash
go run main.go
```

### Docker Compose
```bash
docker-compose up --build
```

### Docker Individual
```bash
# Serviço A
docker run -e SERVICE=A -p 8080:8080 <image>

# Serviço B  
docker run -e SERVICE=B -p 8081:8081 <image>
```

## Testes

Execute o script de testes:
```bash
./test.sh
```

## OpenTelemetry + Zipkin

### Tracing Distribuído
Este projeto implementa **tracing distribuído** usando OpenTelemetry com Zipkin como backend de observabilidade.

#### Spans Implementados:
- 🔍 **service-a-input**: Validação de input no Serviço A
- 🌐 **call-service-b**: Comunicação entre Serviço A → Serviço B  
- 🔄 **service-b-weather**: Orquestração no Serviço B
- 📍 **fetch-cep-info**: Busca de localização (API ViaCEP)
- 🌡️ **fetch-weather-info**: Busca de temperatura (WeatherAPI)

#### Métricas Capturadas:
- ⏱️ **Tempo de resposta** de cada operação
- 🏷️ **Atributos**: CEP, cidade, temperaturas
- ❌ **Erros** e status de cada chamada
- 🔗 **Correlação** entre requisições distribuídas

### Visualização
```bash
# Subir com Zipkin
make docker-compose-up

# Fazer requisições para gerar traces
make trace-demo

# Abrir interface do Zipkin
make zipkin-ui
```

**Zipkin UI**: `http://localhost:9411`

## Variáveis de Ambiente

- `SERVICE`: Define qual serviço executar (`A` ou `B`)
- `SERVICE_B_URL`: URL do Serviço B (padrão: `http://localhost:8081`)
- `ZIPKIN_ENDPOINT`: URL do Zipkin (padrão: `http://localhost:9411/api/v2/spans`)
