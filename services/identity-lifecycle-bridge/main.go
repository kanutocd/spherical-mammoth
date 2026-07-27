package main

import (
	"context"
	"encoding/json"
	"errors"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type server struct {
	db *pgxpool.Pool
}

type lifecycleRequest struct {
	IdentityID      string  `json:"identity_id"`
	Email           string  `json:"email"`
	DisplayName     *string `json:"display_name"`
	VerificationURL *string `json:"verification_url"`
}

func main() {
	databaseURL := os.Getenv("DATABASE_URL")
	if databaseURL == "" {
		log.Fatal("DATABASE_URL is required")
	}

	db, err := pgxpool.New(context.Background(), databaseURL)
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	s := &server{db: db}
	mux := http.NewServeMux()
	mux.HandleFunc("GET /health/live", ok)
	mux.HandleFunc("GET /health/ready", s.ready)
	mux.HandleFunc("POST /v1/lifecycle/verification-requested", s.verificationRequested)
	mux.HandleFunc("POST /v1/lifecycle/signup-completed", s.signupCompleted)

	addr := envOr("LISTEN_ADDR", ":8080")
	log.Printf("identity lifecycle bridge listening on %s", addr)
	if err := http.ListenAndServe(addr, logging(cors(mux))); err != nil {
		log.Fatal(err)
	}
}

func cors(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		origin := r.Header.Get("Origin")
		if origin != "" && allowedOrigin(origin) {
			w.Header().Set("Access-Control-Allow-Origin", origin)
			w.Header().Add("Vary", "Origin")
		}
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Accept")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func allowedOrigin(origin string) bool {
	configured := envOr("CORS_ALLOWED_ORIGIN", "http://localhost:3000")
	for _, candidate := range strings.Split(configured, ",") {
		if strings.TrimSpace(candidate) == origin {
			return true
		}
	}
	return false
}

func (s *server) verificationRequested(w http.ResponseWriter, r *http.Request) {
	request, ok := decodeLifecycleRequest(w, r)
	if !ok {
		return
	}

	tx, err := s.db.Begin(r.Context())
	if err != nil {
		serverError(w, err)
		return
	}
	defer tx.Rollback(r.Context())

	var signupID string
	err = tx.QueryRow(r.Context(), `
		INSERT INTO signup_requests (id, identity_id, email, display_name, status)
		VALUES (gen_random_uuid(), $1, $2, $3, 'verification_requested')
		ON CONFLICT (identity_id) DO UPDATE
		SET email = EXCLUDED.email, display_name = EXCLUDED.display_name
		RETURNING id
	`, request.IdentityID, request.Email, request.DisplayName).Scan(&signupID)
	if err != nil {
		serverError(w, err)
		return
	}

	data := map[string]any{
		"signup_request_id": signupID,
		"identity_id":       request.IdentityID,
		"email":             request.Email,
		"display_name":      request.DisplayName,
		"verification_url":  request.VerificationURL,
	}
	eventID, err := insertEvent(r.Context(), tx, "identity.verification_requested", signupID, data)
	if err != nil {
		serverError(w, err)
		return
	}
	if err := tx.Commit(r.Context()); err != nil {
		serverError(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"event_id": eventID, "signup_request_id": signupID})
}

func (s *server) signupCompleted(w http.ResponseWriter, r *http.Request) {
	request, ok := decodeLifecycleRequest(w, r)
	if !ok {
		return
	}

	tx, err := s.db.Begin(r.Context())
	if err != nil {
		serverError(w, err)
		return
	}
	defer tx.Rollback(r.Context())

	var signupID string
	err = tx.QueryRow(r.Context(), `
		UPDATE signup_requests
		SET status = 'completed', completed_at = now(), email = $2, display_name = $3
		WHERE identity_id = $1
		RETURNING id
	`, request.IdentityID, request.Email, request.DisplayName).Scan(&signupID)
	if errors.Is(err, pgx.ErrNoRows) {
		http.Error(w, "signup request not found", http.StatusConflict)
		return
	}
	if err != nil {
		serverError(w, err)
		return
	}

	var accountID string
	err = tx.QueryRow(r.Context(), `
		INSERT INTO accounts (id, identity_id, email, display_name)
		VALUES (gen_random_uuid(), $1, $2, $3)
		ON CONFLICT (identity_id) DO UPDATE
		SET email = EXCLUDED.email, display_name = EXCLUDED.display_name
		RETURNING id
	`, request.IdentityID, request.Email, request.DisplayName).Scan(&accountID)
	if err != nil {
		serverError(w, err)
		return
	}

	data := map[string]any{
		"account_id":   accountID,
		"identity_id":  request.IdentityID,
		"email":        request.Email,
		"display_name": request.DisplayName,
	}
	eventID, err := insertEvent(r.Context(), tx, "identity.signup_completed", accountID, data)
	if err != nil {
		serverError(w, err)
		return
	}
	if err := tx.Commit(r.Context()); err != nil {
		serverError(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, map[string]string{"event_id": eventID, "account_id": accountID, "signup_request_id": signupID})
}

type querier interface {
	QueryRow(context.Context, string, ...any) pgx.Row
}

func insertEvent(ctx context.Context, q querier, eventType, aggregateID string, data map[string]any) (string, error) {
	payload, err := json.Marshal(data)
	if err != nil {
		return "", err
	}
	var eventID string
	err = q.QueryRow(ctx, `
		INSERT INTO domain_events (event_id, event_type, aggregate_id, data)
		VALUES (gen_random_uuid(), $1, $2, $3)
		RETURNING event_id
	`, eventType, aggregateID, payload).Scan(&eventID)
	return eventID, err
}

func decodeLifecycleRequest(w http.ResponseWriter, r *http.Request) (lifecycleRequest, bool) {
	var request lifecycleRequest
	decoder := json.NewDecoder(http.MaxBytesReader(w, r.Body, 1<<20))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&request); err != nil {
		http.Error(w, "invalid JSON payload", http.StatusBadRequest)
		return request, false
	}
	if request.IdentityID == "" || request.Email == "" {
		http.Error(w, "identity_id and email are required", http.StatusBadRequest)
		return request, false
	}
	return request, true
}

func (s *server) ready(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), time.Second)
	defer cancel()
	if err := s.db.Ping(ctx); err != nil {
		http.Error(w, "database unavailable", http.StatusServiceUnavailable)
		return
	}
	ok(w, r)
}

func ok(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

func writeJSON(w http.ResponseWriter, status int, value any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(value)
}

func serverError(w http.ResponseWriter, err error) {
	log.Printf("request failed: %v", err)
	http.Error(w, "internal server error", http.StatusInternalServerError)
}

func logging(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		started := time.Now()
		next.ServeHTTP(w, r)
		log.Printf("%s %s %s", r.Method, r.URL.Path, time.Since(started))
	})
}

func envOr(name, fallback string) string {
	if value := os.Getenv(name); value != "" {
		return value
	}
	return fallback
}
