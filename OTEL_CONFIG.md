# Configuração para Produção - OpenTelemetry + Zipkin

## Variáveis de Ambiente Recomendadas

### Desenvolvimento Local
```bash
export SERVICE=A                                    # ou B
export SERVICE_B_URL=http://localhost:8081
export ZIPKIN_ENDPOINT=http://localhost:9411/api/v2/spans
```

### Docker Compose
```yaml
environment:
  - SERVICE=A
  - SERVICE_B_URL=http://service-b:8081  
  - ZIPKIN_ENDPOINT=http://zipkin:9411/api/v2/spans
```

### Kubernetes
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: otel-config
data:
  SERVICE: "A"
  SERVICE_B_URL: "http://service-b:8081"
  ZIPKIN_ENDPOINT: "http://zipkin:9411/api/v2/spans"
```

## Configurações Avançadas

### Sampling
Por padrão, 100% dos traces são coletados. Para produção, considere:
```go
// Adicionar ao initTracer()
trace.WithSampler(trace.TraceIDRatioBased(0.1)) // 10% dos traces
```

### Recursos Customizados
```go
resource.NewWithAttributes(
    semconv.SchemaURL,
    semconv.ServiceName(serviceName),
    semconv.ServiceVersion("1.0.0"),
    semconv.DeploymentEnvironment("production"),
    attribute.String("service.instance.id", hostname),
)
```

### Outros Exporters
- **Jaeger**: `go.opentelemetry.io/otel/exporters/jaeger`
- **OTLP**: `go.opentelemetry.io/otel/exporters/otlp/otlptrace`
- **Prometheus**: Para métricas

## Monitoramento

### Métricas Importantes
- Latência P50, P95, P99 por endpoint
- Taxa de erro por serviço  
- Throughput (req/s)
- Dependência externa (ViaCEP, WeatherAPI)

### Alertas Sugeridos
- Latência > 5s em qualquer span
- Taxa de erro > 5% em 5 minutos
- Falha de conectividade entre serviços
- APIs externas com timeout

### Dashboards Zipkin
1. **Service Dependencies**: Visualizar comunicação entre serviços
2. **Trace Timeline**: Analisar latência de operações
3. **Error Analysis**: Identificar padrões de falha
4. **API Performance**: Monitorar APIs externas