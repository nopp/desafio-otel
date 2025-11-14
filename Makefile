.PHONY: build run test clean docker-build docker-run docker-compose-up docker-compose-down

# Variáveis
BINARY_NAME=main
DOCKER_IMAGE=desafio-otel

# Build da aplicação
build:
	go build -o $(BINARY_NAME) .

# Executar aplicação local (ambos serviços)
run: build
	./$(BINARY_NAME)

# Executar apenas Serviço A
run-service-a: build
	SERVICE=A ./$(BINARY_NAME)

# Executar apenas Serviço B  
run-service-b: build
	SERVICE=B ./$(BINARY_NAME)

# Executar testes
test:
	./test.sh

# Demonstração do tracing distribuído
trace-demo:
	./trace-demo.sh

# Demo completo com verificação de Zipkin
demo:
	./demo-completo.sh

# Abrir interface do Zipkin
zipkin-ui:
	@echo "Abrindo Zipkin UI..."
	@open http://localhost:9411 2>/dev/null || echo "Acesse manualmente: http://localhost:9411"

# Limpar binários
clean:
	rm -f $(BINARY_NAME)

# Build da imagem Docker
docker-build:
	docker build -t $(DOCKER_IMAGE) .

# Executar container Docker (Serviço A)
docker-run-a: docker-build
	docker run -p 8080:8080 -e SERVICE=A $(DOCKER_IMAGE)

# Executar container Docker (Serviço B)
docker-run-b: docker-build
	docker run -p 8081:8081 -e SERVICE=B $(DOCKER_IMAGE)

# Subir ambos serviços com Docker Compose
docker-compose-up:
	docker-compose up --build

# Parar Docker Compose
docker-compose-down:
	docker-compose down

# Executar em background para testes
run-background: build
	./$(BINARY_NAME) &
	@echo "Serviços rodando em background. Para parar: make stop-background"

# Parar processo em background
stop-background:
	pkill -f "./$(BINARY_NAME)" || true

# Verificar se os serviços estão rodando
check-services:
	@echo "Verificando Serviço A (porta 8080)..."
	@curl -s -o /dev/null -w "Status: %{http_code}\n" http://localhost:8080 || echo "Serviço A não está respondendo"
	@echo "Verificando Serviço B (porta 8081)..."
	@curl -s -o /dev/null -w "Status: %{http_code}\n" http://localhost:8081/weather?cep=01310100 || echo "Serviço B não está respondendo"

# Ajuda
help:
	@echo "Comandos disponíveis:"
	@echo "  build              - Compila a aplicação"
	@echo "  run                - Executa ambos os serviços localmente"
	@echo "  run-service-a      - Executa apenas o Serviço A"
	@echo "  run-service-b      - Executa apenas o Serviço B"
	@echo "  test               - Executa os testes"
	@echo "  trace-demo         - Demonstração do tracing distribuído"
	@echo "  demo               - Demo completo com verificação de Zipkin"
	@echo "  zipkin-ui          - Abre a interface do Zipkin"
	@echo "  docker-compose-up  - Sobe ambos serviços via Docker Compose"
	@echo "  docker-compose-down - Para os serviços do Docker Compose"
	@echo "  run-background     - Executa em background para testes"
	@echo "  stop-background    - Para os processos em background"
	@echo "  check-services     - Verifica se os serviços estão rodando"
	@echo "  clean              - Remove binários compilados"