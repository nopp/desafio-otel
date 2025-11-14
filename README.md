# Desafio OTEL - CEP e Clima

Sistema que valida CEP e retorna temperaturas com tracing completo.

## 1. Setup inicial

```bash
git clone https://github.com/nopp/desafio-otel.git
cd desafio-otel
./setup-dev.sh
```

## 2. Como testar

```bash
./test.sh
```

## 3. Ver tracing

- Abrir: http://localhost:9411
- Clicar em "Run Query"

## 4. Comandos úteis

- `make demo` - Testa automaticamente  
- `make dev-logs` - Ver logs em tempo real
- `make dev-down` - Parar tudo