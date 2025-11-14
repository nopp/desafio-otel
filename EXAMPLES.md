# Exemplos de Requisições

## Serviço A (Input/Validação) - Porta 8080

### ✅ Requisição válida
```bash
curl -X POST http://localhost:8080 \
  -H "Content-Type: application/json" \
  -d '{"cep": "01310100"}'
```

**Resposta esperada (200):**
```json
{
  "city": "São Paulo",
  "temp_C": 20.2,
  "temp_F": 68.4,
  "temp_K": 293.35
}
```

### ❌ CEP inválido - formato incorreto
```bash
curl -X POST http://localhost:8080 \
  -H "Content-Type: application/json" \
  -d '{"cep": "123"}'
```

**Resposta esperada (422):**
```
invalid zipcode
```

### ❌ CEP inválido - caracteres não numéricos
```bash
curl -X POST http://localhost:8080 \
  -H "Content-Type: application/json" \
  -d '{"cep": "abcdefgh"}'
```

**Resposta esperada (422):**
```
invalid zipcode
```

### ❌ CEP não encontrado
```bash
curl -X POST http://localhost:8080 \
  -H "Content-Type: application/json" \
  -d '{"cep": "99999999"}'
```

**Resposta esperada (404):**
```
can not find zipcode
```

### ❌ Método não permitido
```bash
curl -X GET http://localhost:8080
```

**Resposta esperada (405):**
```
method not allowed
```

## Serviço B (Orquestração) - Porta 8081

### ✅ Requisição válida
```bash
curl "http://localhost:8081/weather?cep=01310100"
```

**Resposta esperada (200):**
```json
{
  "city": "São Paulo",
  "temp_C": 20.2,
  "temp_F": 68.4,
  "temp_K": 293.35
}
```

### ❌ CEP inválido
```bash
curl "http://localhost:8081/weather?cep=123"
```

**Resposta esperada (422):**
```
invalid zipcode
```

### ❌ CEP não encontrado
```bash
curl "http://localhost:8081/weather?cep=99999999"
```

**Resposta esperada (404):**
```
can not find zipcode
```

## Códigos de Status HTTP

| Código | Significado | Quando ocorre |
|--------|-------------|---------------|
| 200    | OK          | CEP válido e encontrado |
| 404    | Not Found   | CEP válido mas não encontrado |
| 405    | Method Not Allowed | Método HTTP incorreto |
| 422    | Unprocessable Entity | CEP com formato inválido |