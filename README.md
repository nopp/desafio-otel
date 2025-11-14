# Desafio OTEL - CEP e Clima

Sistema que valida CEP e retorna temperaturas com tracing completo.

## 1. Iniciar projeto

```bash
git clone https://github.com/nopp/desafio-otel.git
cd desafio-otel
./setup-dev.sh
```

## 2. Como testar

### Teste automático
```bash
./test.sh
```

### Teste manual
```bash
# CEP válido (sucesso)
curl -X POST http://localhost:8080 \
  -H "Content-Type: application/json" \
  -d '{"cep": "01310100"}'

# CEP inválido (erro)
curl -X POST http://localhost:8080 \
  -H "Content-Type: application/json" \
  -d '{"cep": "123"}'
```

## 3. Ver tracing

- Abrir: http://localhost:9411
- Clicar em "Run Query"
- Ver os spans distribuídos entre serviços

## 4. Comandos úteis

- `make demo` - Testa automaticamente  
- `make dev-logs` - Ver logs em tempo real
- `make dev-down` - Parar tudo