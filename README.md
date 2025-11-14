# Desafio OTEL - CEP e Clima

Sistema que valida CEP e retorna temperaturas com tracing completo.

## Como usar

```bash
# 1. Baixar e configurar
git clone https://github.com/nopp/desafio-otel.git
cd desafio-otel
./setup-dev.sh

# 2. Testar
curl -X POST http://localhost:8080 \
  -H "Content-Type: application/json" \
  -d '{"cep": "01310100"}'
```

## Acessos

- **API**: http://localhost:8080
- **Zipkin**: http://localhost:9411

## Comandos úteis

- `make demo` - Testes completos
- `make dev-logs` - Ver logs
- `make dev-down` - Parar tudo

## Como funciona

1. **POST** para `/` com `{"cep": "01310100"}`
2. **Valida** o CEP (8 dígitos)
3. **Busca** cidade na API ViaCEP
4. **Busca** temperatura na API WeatherAPI  
5. **Retorna** `{"city": "São Paulo", "temp_C": 25.0, "temp_F": 77.0, "temp_K": 298.15}`

## Tracing

O sistema gera **traces** de todas as operações que você pode ver no Zipkin em http://localhost:9411

## Mais informações

- **[EXAMPLES.md](./EXAMPLES.md)**: Mais exemplos de uso
- **[QUICK_START.md](./QUICK_START.md)**: Setup ainda mais rápido
