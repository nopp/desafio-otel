# Exemplos de Uso

## Requisição de sucesso

```bash
curl -X POST http://localhost:8080 \
  -H "Content-Type: application/json" \
  -d '{"cep": "01310100"}'
```

Resposta:
```json
{
  "city": "São Paulo",
  "temp_C": 20.2,
  "temp_F": 68.4,
  "temp_K": 293.35
}
```

## CEP inválido

```bash
curl -X POST http://localhost:8080 \
  -H "Content-Type: application/json" \
  -d '{"cep": "123"}'
```

Resposta: `invalid zipcode` (Status 422)

## CEP não encontrado

```bash
curl -X POST http://localhost:8080 \
  -H "Content-Type: application/json" \
  -d '{"cep": "99999999"}'
```

Resposta: `can not find zipcode` (Status 404)

## Códigos de retorno

- **200**: Sucesso
- **404**: CEP não encontrado  
- **422**: CEP inválido