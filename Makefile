SHELL := /bin/bash
include .env
export

# Map .env variable names to Makefile names
REMOTE_DIR := $(REMOTE_PATH)

# Makefile for building and deploying fraktionsprotokolle-static
#
# Dependency graph (use 'make -j4' for parallel execution):
#
#   config ──┐
#   css    ──┼── build ── upload
#   fetch ─┬─┤
#          │ └── makeHTML
#          └── indices

# Environment (live or test) - default is live
ENV ?= live

# Local directory to upload
LOCAL_DIR := ./html
COPY_DIR := ../public_html/
# API settings
API_DIR := ./api
API_BINARY := kgparl-api
REMOTE_API_DIR := $(REMOTE_DIR)/api

.PHONY: all build config css fetch indices makeHTML upload help css-watch api-build api-deploy api-install-supervisor

# Default: build and upload
#all: build makePDF upload
all: build makePDF copy

# Build everything - with 'make -j4 build' these run in parallel where possible
build: config css indices makeHTML

# --- Independent targets (no dependencies, can run in parallel) ---

config:
	@echo "Generating JS config for environment: $(ENV)"
	/usr/bin/python3 scripts/generate_js_config.py --env $(ENV)

css:
	@echo "Building Tailwind CSS..."
	/usr/home/editih/.linuxbrew/bin/tailwindcss -i ./html/css/tailwind.input.css -o ./html/css/tailwind.css --minify

fetch:
	@echo "Fetching latest changes for environment: $(ENV)"
	./fetch_data.sh $(ENV)

# --- Targets that depend on fetch (can run in parallel with each other) ---

indices: fetch
	@echo "Generating indices for environment: $(ENV)"
	cd golang && /usr/home/editih/.linuxbrew/bin/go mod tidy && /usr/home/editih/.linuxbrew/bin/go run ./main.go && cd ..
	/usr/bin/python3 make_ts_index.py --env $(ENV) && \
	/usr/bin/python3 make_ts_index_literature.py --env $(ENV) && \
	/usr/bin/python3 make_ts_index_keywords.py --env $(ENV) && \
	/usr/bin/python3 make_calendar_date.py

makeHTML: fetch
	@echo "Generating HTML files"
	ant -lib ./saxon/ -Denv=$(ENV)

makePDF: 
	@echo "Generating PDF files"
	/usr/bin/python3 generate_pdf.py -b ./html/ --env $(ENV)
# --- Final targets ---

upload: 
	@echo "Uploading $(LOCAL_DIR) to $(REMOTE_USER)@$(REMOTE_HOST):$(REMOTE_DIR)"
	rsync -avz --delete $(LOCAL_DIR)/ $(REMOTE_USER)@$(REMOTE_HOST):$(REMOTE_DIR)

copy:
	@echo "Copying ${LOCAL_DIR} to ${COPY_DIR}"
	cp -rf "${LOCAL_DIR}/." "${COPY_DIR}/."

# --- Development helpers ---

css-watch:
	@echo "Watching Tailwind CSS for changes..."
	/usr/home/editih/.linuxbrew/bin/tailwindcss -i ./html/css/tailwind.input.css -o ./html/css/tailwind.css --watch

# --- API targets ---

api-build:
	@echo "Building API for linux/amd64..."
	cd $(API_DIR) && GOOS=linux GOARCH=amd64 go build -o $(API_BINARY) .

api-deploy: api-build
	@echo "Deploying API to $(REMOTE_HOST)..."
	ssh $(REMOTE_USER)@$(REMOTE_HOST) "mkdir -p $(REMOTE_API_DIR)"
	rsync -avz $(API_DIR)/$(API_BINARY) $(REMOTE_USER)@$(REMOTE_HOST):$(REMOTE_API_DIR)/
	rsync -avz ./config/kgparl-api.supervisor.conf $(REMOTE_USER)@$(REMOTE_HOST):/tmp/
	ssh $(REMOTE_USER)@$(REMOTE_HOST) "sudo mv /tmp/kgparl-api.supervisor.conf /etc/supervisor/conf.d/kgparl-api.conf && sudo supervisorctl reread && sudo supervisorctl update && sudo supervisorctl restart kgparl-api"
	@echo "API deployed and restarted."

api-install-supervisor:
	@echo "Installing supervisor on $(REMOTE_HOST)..."
	ssh $(REMOTE_USER)@$(REMOTE_HOST) "sudo apt update && sudo apt install -y supervisor && sudo systemctl enable supervisor && sudo systemctl start supervisor"

# Help target
help:
	@echo "Available targets:"
	@echo "  all       - Build everything and upload (default)"
	@echo "  build     - Build without uploading"
	@echo "  config    - Generate JS configuration"
	@echo "  css       - Build Tailwind CSS (minified)"
	@echo "  css-watch - Watch and rebuild Tailwind CSS on changes"
	@echo "  fetch     - Fetch data from GitHub"
	@echo "  indices   - Generate Typesense indices"
	@echo "  makeHTML  - Generate HTML files via ant"
	@echo "  upload    - Upload $(LOCAL_DIR) to remote server"
	@echo "  api-build - Cross-compile API binary for linux/amd64"
	@echo "  api-deploy - Build, upload, and restart API via supervisor"
	@echo "  api-install-supervisor - Install supervisor on remote (one-time)"
	@echo "  help      - Display this help message"
	@echo ""
	@echo "Environment variable:"
	@echo "  ENV=live  - Use live environment (default)"
	@echo "  ENV=test  - Use test environment"
	@echo ""
	@echo "Parallel build (recommended):"
	@echo "  make -j4 all         - Full build + upload with 4 parallel jobs"
	@echo "  make -j4 build       - Build only, no upload"
	@echo ""
	@echo "Examples:"
	@echo "  make all ENV=live    - Build and upload for live environment"
	@echo "  make all ENV=test    - Build and upload for test environment"
	@echo "  make build           - Build only (no upload)"
	@echo "  make css-watch       - Development mode with CSS hot-reload"
