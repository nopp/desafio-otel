# Solução de Problemas

## ❌ `connection refused` no Zipkin (porta 9411)

**Erro**: `dial tcp [::1]:9411: connect: connection refused`

**Causa**: Docker não está rodando

**Solução**:
1. Abrir Docker Desktop
2. Aguardar inicializar completamente  
3. Rodar: `./setup-dev.sh`

## ❌ `Cannot connect to Docker daemon`

**Causa**: Docker Desktop não está rodando

**Solução**:
1. Abrir Docker Desktop
2. Aguardar ver "Engine running" 
3. Tentar novamente

## ❌ Serviços não respondem (8080/8081)

**Verificar containers**:
```bash
docker-compose ps
```

**Reiniciar**:
```bash
make dev-down
./setup-dev.sh
```

## ❌ Erro de permissão nos scripts

**Solução**:
```bash
chmod +x *.sh
```

## 🆘 Reset completo

```bash
make dev-down
docker-compose down --volumes
./setup-dev.sh
```