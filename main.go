package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"os"
	"time"
	"unicode"

	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/exporters/zipkin"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.26.0"
)

const (
	cepUrl     = "https://viacep.com.br/ws/"
	weatherUrl = "http://api.weatherapi.com/v1/current.json?key=3e67e3649e5e49bab99153600251111&aqi=no"
)

// Structs para requisição e resposta
type CEPRequest struct {
	CEP string `json:"cep"`
}

type CEPResponse struct {
	Localidade string `json:"localidade"`
	Erro       string `json:"erro"`
}

type WeatherResponse struct {
	Current struct {
		TempC float64 `json:"temp_c"`
		TempF float64 `json:"temp_f"`
	} `json:"current"`
}

type TemperatureResponse struct {
	City  string  `json:"city"`
	TempC float64 `json:"temp_C"`
	TempF float64 `json:"temp_F"`
	TempK float64 `json:"temp_K"`
}

func main() {
	// Inicializar OpenTelemetry
	shutdown := initTracer()
	defer shutdown()

	service := os.Getenv("SERVICE")

	switch service {
	case "A":
		startServiceA()
	case "B":
		startServiceB()
	default:
		// Para desenvolvimento local, rode ambos os serviços
		log.Println("Running both services for development")
		go startServiceA()
		startServiceB()
	}
}

// Inicializar OpenTelemetry com Zipkin
func initTracer() func() {
	zipkinEndpoint := os.Getenv("ZIPKIN_ENDPOINT")
	if zipkinEndpoint == "" {
		zipkinEndpoint = "http://localhost:9411/api/v2/spans"
	}

	serviceName := os.Getenv("SERVICE")
	if serviceName == "" {
		serviceName = "desafio-otel"
	} else {
		serviceName = "service-" + serviceName
	}

	exporter, err := zipkin.New(zipkinEndpoint)
	if err != nil {
		log.Printf("Failed to create Zipkin exporter: %v", err)
		return func() {}
	}

	tp := sdktrace.NewTracerProvider(
		sdktrace.WithBatcher(exporter),
		sdktrace.WithResource(resource.NewWithAttributes(
			semconv.SchemaURL,
			semconv.ServiceName(serviceName),
			semconv.ServiceVersion("1.0.0"),
		)),
	)

	otel.SetTracerProvider(tp)
	otel.SetTextMapPropagator(propagation.TraceContext{})

	return func() {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		tp.Shutdown(ctx)
	}
} // Serviço A - Responsável pelo input
func startServiceA() {
	mux := http.NewServeMux()
	mux.Handle("/", otelhttp.NewHandler(http.HandlerFunc(inputHandler), "service-a-input"))

	addr := ":8080"
	log.Printf("Service A listening on %s", addr)
	log.Fatal(http.ListenAndServe(addr, mux))
}

// Serviço B - Responsável pela orquestração
func startServiceB() {
	mux := http.NewServeMux()
	mux.Handle("/weather", otelhttp.NewHandler(http.HandlerFunc(weatherHandler), "service-b-weather"))

	addr := ":8081"
	log.Printf("Service B listening on %s", addr)
	log.Fatal(http.ListenAndServe(addr, mux))
}

// Handler do Serviço A - Validação de input
func inputHandler(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	tracer := otel.Tracer("service-a")
	ctx, span := tracer.Start(ctx, "input-validation")
	defer span.End()

	if r.Method != http.MethodPost {
		span.RecordError(fmt.Errorf("method not allowed"))
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req CEPRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		span.RecordError(err)
		http.Error(w, "invalid zipcode", http.StatusUnprocessableEntity)
		return
	}

	// Validar se o CEP é válido (8 dígitos e string)
	if !isValidCEP(req.CEP) {
		span.RecordError(fmt.Errorf("invalid CEP format: %s", req.CEP))
		http.Error(w, "invalid zipcode", http.StatusUnprocessableEntity)
		return
	}

	span.SetAttributes(attribute.String("cep", req.CEP))

	// Encaminhar para o Serviço B
	serviceBURL := os.Getenv("SERVICE_B_URL")
	if serviceBURL == "" {
		serviceBURL = "http://localhost:8081" // Default para desenvolvimento
	}

	// Criar span para chamada ao Serviço B
	ctx, callSpan := tracer.Start(ctx, "call-service-b")
	callSpan.SetAttributes(attribute.String("service.url", serviceBURL))

	// Criar cliente HTTP com instrumentação OpenTelemetry
	client := &http.Client{
		Transport: otelhttp.NewTransport(http.DefaultTransport),
	}

	req2, _ := http.NewRequestWithContext(ctx, "GET", fmt.Sprintf("%s/weather?cep=%s", serviceBURL, req.CEP), nil)
	resp, err := client.Do(req2)
	if err != nil {
		callSpan.RecordError(err)
		callSpan.End()
		http.Error(w, "service unavailable", http.StatusServiceUnavailable)
		return
	}
	defer resp.Body.Close()
	callSpan.End()

	// Repassar a resposta do Serviço B
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(resp.StatusCode)

	// Copiar o corpo da resposta
	var response interface{}
	if err := json.NewDecoder(resp.Body).Decode(&response); err == nil {
		json.NewEncoder(w).Encode(response)
	}
}

func weatherHandler(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	tracer := otel.Tracer("service-b")
	ctx, span := tracer.Start(ctx, "weather-orchestration")
	defer span.End()

	if r.Method != http.MethodGet {
		span.RecordError(fmt.Errorf("method not allowed"))
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	cep := r.URL.Query().Get("cep")
	if !isValidCEP(cep) {
		span.RecordError(fmt.Errorf("invalid CEP format: %s", cep))
		http.Error(w, "invalid zipcode", http.StatusUnprocessableEntity)
		return
	}

	span.SetAttributes(attribute.String("cep", cep))

	cepInformation := CEPResponse{}
	cityInformation := WeatherResponse{}

	// Criar cliente HTTP com instrumentação OpenTelemetry
	client := &http.Client{
		Transport: otelhttp.NewTransport(http.DefaultTransport),
	}

	// Span para busca de CEP
	ctx, cepSpan := tracer.Start(ctx, "fetch-cep-info")
	cepSpan.SetAttributes(attribute.String("cep.api.url", cepUrl))
	cepReq, _ := http.NewRequestWithContext(ctx, "GET", fmt.Sprintf("%s%s/json/", cepUrl, cep), nil)
	resp, err := client.Do(cepReq)
	if err != nil {
		cepSpan.RecordError(err)
		cepSpan.End()
		http.Error(w, "failed to reach CEP service", http.StatusBadGateway)
		return
	}
	defer resp.Body.Close()

	switch resp.StatusCode {
	case http.StatusNotFound:
		cepSpan.RecordError(fmt.Errorf("CEP not found"))
		cepSpan.End()
		http.Error(w, "can not find zipcode", http.StatusNotFound)
		return
	case http.StatusBadRequest, http.StatusUnprocessableEntity:
		cepSpan.RecordError(fmt.Errorf("invalid CEP"))
		cepSpan.End()
		http.Error(w, "invalid zipcode", http.StatusUnprocessableEntity)
		return
	case http.StatusOK:
	default:
		cepSpan.RecordError(fmt.Errorf("CEP service error: %d", resp.StatusCode))
		cepSpan.End()
		http.Error(w, "cep service error", http.StatusBadGateway)
		return
	}

	if err := json.NewDecoder(resp.Body).Decode(&cepInformation); err != nil {
		cepSpan.RecordError(err)
		cepSpan.End()
		http.Error(w, "invalid cep response", http.StatusBadGateway)
		return
	}
	if cepInformation.Erro == "true" {
		cepSpan.RecordError(fmt.Errorf("CEP not found in response"))
		cepSpan.End()
		http.Error(w, "can not find zipcode", http.StatusNotFound)
		return
	}

	cepSpan.SetAttributes(attribute.String("cep.city", cepInformation.Localidade))
	cepSpan.End()

	// Span para busca de clima
	ctx, weatherSpan := tracer.Start(ctx, "fetch-weather-info")
	weatherSpan.SetAttributes(
		attribute.String("weather.api.url", weatherUrl),
		attribute.String("weather.city", cepInformation.Localidade),
	)

	weatherReq, _ := http.NewRequestWithContext(ctx, "GET", weatherUrl+"&q="+url.QueryEscape(cepInformation.Localidade), nil)
	respW, err := client.Do(weatherReq)
	if err != nil {
		weatherSpan.RecordError(err)
		weatherSpan.End()
		http.Error(w, "failed to reach weather service", http.StatusBadGateway)
		return
	}
	defer respW.Body.Close()

	if respW.StatusCode != http.StatusOK {
		weatherSpan.RecordError(fmt.Errorf("weather service error: %d", respW.StatusCode))
		weatherSpan.End()
		http.Error(w, "can not find zipcode", http.StatusBadGateway)
		return
	}

	if err := json.NewDecoder(respW.Body).Decode(&cityInformation); err != nil {
		weatherSpan.RecordError(err)
		weatherSpan.End()
		http.Error(w, "invalid weather response", http.StatusBadGateway)
		return
	}

	weatherSpan.SetAttributes(
		attribute.Float64("weather.temp_c", cityInformation.Current.TempC),
		attribute.Float64("weather.temp_f", cityInformation.Current.TempF),
	)
	weatherSpan.End()

	cityResponse := TemperatureResponse{
		City:  cepInformation.Localidade,
		TempC: cityInformation.Current.TempC,
		TempF: cityInformation.Current.TempF,
		TempK: cityInformation.Current.TempC + 273.15,
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(cityResponse); err != nil {
		http.Error(w, "failed to encode response", http.StatusInternalServerError)
		return
	}
}

func isValidCEP(cep string) bool {
	if len(cep) != 8 {
		return false
	}
	for _, r := range cep {
		if !unicode.IsDigit(r) {
			return false
		}
	}
	return true
}
