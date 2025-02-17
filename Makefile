# Sample makefile, NOTE: will be edited later
.PHONY: help install install-dev migrate run test lint format clean build docker-build docker-run

# Variables
PYTHON = python
PIP = pip
MANAGE = src/manage.py
DOCKER_COMPOSE = docker-compose

help: ## Show this help message
	@echo 'Usage:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

install: ## Install production dependencies
	$(PIP) install -r src/requirements/production.txt

install-dev: ## Install development dependencies
	$(PIP) install -r src/requirements/local.txt
	pre-commit install

migrate: ## Run database migrations
	$(PYTHON) $(MANAGE) makemigrations
	$(PYTHON) $(MANAGE) migrate

run: ## Run development server
	$(PYTHON) $(MANAGE) runserver 0.0.0.0:8080

test: ## Run tests
	$(PYTHON) $(MANAGE) test tests/ apps/ --verbosity=2

coverage: ## Run tests with coverage report
	coverage run $(MANAGE) test tests/ apps/
	coverage report
	coverage html

lint: ## Run code linting
	ruff check src/

format: ## Format code
	ruff format src/


clean: ## Remove cache files
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	find . -type f -name "*.pyo" -delete
	find . -type f -name "*.pyd" -delete
	find . -type f -name ".coverage" -delete
	find . -type d -name "*.egg-info" -exec rm -rf {} +
	find . -type d -name "*.egg" -exec rm -rf {} +
	find . -type d -name ".pytest_cache" -exec rm -rf {} +
	find . -type d -name ".mypy_cache" -exec rm -rf {} +
	find . -type d -name ".coverage" -exec rm -rf {} +
	find . -type d -name "htmlcov" -exec rm -rf {} +

shell: ## Enter Django shell
	$(PYTHON) $(MANAGE) shell

collectstatic: ## Collect static files
	$(PYTHON) $(MANAGE) collectstatic --noinput

# Docker commands
docker-build: ## Build Docker images
	$(DOCKER_COMPOSE) -f deployment/docker/docker-compose.yaml build
	docker tag web myapp:$(shell git rev-parse --short HEAD)
	docker tag web myapp:latest

docker-up: ## Start Docker containers
	$(DOCKER_COMPOSE) -f deployment/docker/docker-compose.yaml --env-file .env up -d

docker-down: ## Stop Docker containers
	$(DOCKER_COMPOSE) -f deployment/docker/docker-compose.yaml down

docker-logs: ## View Docker logs
	$(DOCKER_COMPOSE) -f deployment/docker/docker-compose.yaml logs -f

# Database commands
db-backup: ## Backup database
	$(PYTHON) $(MANAGE) dumpdata > backup.json

db-restore: ## Restore database from backup
	$(PYTHON) $(MANAGE) loaddata backup.json

# Dependency management
deps-update: ## Update dependencies
	pip-compile src/requirements/base.in
	pip-compile src/requirements/local.in
	pip-compile src/requirements/production.in

# Development helpers
createsuperuser: ## Create a superuser
	$(PYTHON) $(MANAGE) createsuperuser

makemessages: ## Create/update translation files
	$(PYTHON) $(MANAGE) makemessages -l en

compilemessages: ## Compile translation files
	$(PYTHON) $(MANAGE) compilemessages

# Deployment commands
deploy-check: ## Check deployment requirements
	$(PYTHON) $(MANAGE) check --deploy
	$(PYTHON) $(MANAGE) makemigrations --check
