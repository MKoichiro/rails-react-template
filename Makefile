.PHONY: db

# Load the environment variables in the .env file as Make variables.
ifneq (,$(wildcard .env))
include .env
endif

ENV?=dev
ENVIRONMENT=development
ifeq ($(ENV), prod)
ENVIRONMENT=production
else ifeq ($(ENV), test)
ENVIRONMENT=$(ENV)
else ifneq ($(ENV), dev)
$(error ERROR: Unkown value for ENV: "$(ENV)". Only 'dev' or 'prod' or 'test' are allowed)
endif
COMPOSE_FILE=compose.yml
COMPOSE_FILE_FLAG=-f $(COMPOSE_FILE)
COMPOSE_CMD=docker compose
API_SERVICE_NAME=api
DB_SERVICE_NAME=db
WEB_SERVICE_NAME=web
DB_NAME=api_$(ENVIRONMENT)

# Set up the current directory as the Docker Compose context
dcom_context:
	@curl -L -o rails-react-template.zip https://raw.githubusercontent.com/MKoichiro/rails-react-template/archive/refs/heads/main.zip
	@unzip -o -qq rails-react-template.zip && rm rails-react-template.zip
	@mv rails-react-template-main/* .
	@rm -rf rails-react-template-main/
	@echo "Open with Visual Studio Code (or cursor)? (yes/no/cursor): "
	@read answer; \
	if echo "$$answer" | grep -Eq '^(Y|y|YES|yes|Yes|YEs|YeS|yEs|yeS)$$'; then \
		code .; \
	elif echo "$$answer" | grep -e '^cursor$$'; then \
		cursor .; \
	else \
		echo "Canceled."; \
	fi


# [ LAUNCHERS ]
# - Run `rails new` in an ephemeral api container
api-launch:
	$(COMPOSE_CMD) $(COMPOSE_FILE_FLAG) build $(API_SERVICE_NAME) --no-cache
	$(COMPOSE_CMD) $(COMPOSE_FILE_FLAG) run --rm --no-deps $(API_SERVICE_NAME) bundle exec rails new . --force --skip-bundle --skip-git --database=postgresql --api
# - Create a new React x Typescript x swc app with Vite
web-launch:
	@echo "Create with Vite's offcial template: https://github.com/vitejs/vite-plugin-react-swc"
	@npm create vite@latest ./web -- --template react-swc-ts
	@cd ./web && volta pin node@$(NODE_VER) npm@$(NPM_VER) yarn@$(YARN_VER)
	@cd ./web && npm install
# < ALL >
# - Execute both of `api-launch` and `web-launch`
all-launch:
	@make api-launch
	@make web-launch


# [ SETUP ]
# < OVERWRITE FILES >
# - Overwrite files with the user template in ./template/overwrite/api/
API_OVERWRITE_DIR=./template/overwrite/base/api
api-base-setup:
	@printf "[!] Overwrite the files with user templates in $(API_OVERWRITE_DIR)\n"
	@cp -r --verbose $(API_OVERWRITE_DIR)/database.yml ./api/config/
#   - Overwrite files with the user template in ./template/overwrite/web/
WEB_OVERWRITE_DIR=./template/overwrite/base/web
web-base-setup:
	@printf "[!] Overwrite files with user template in $(WEB_OVERWRITE_DIR)\n"
	@cp -r --verbose $(WEB_OVERWRITE_DIR)/tsconfig.app.json ./web/
	@cp -r --verbose $(WEB_OVERWRITE_DIR)/tsconfig.json ./web/
	@cp -r --verbose $(WEB_OVERWRITE_DIR)/tsconfig.node.json ./web/
	@cp -r --verbose $(WEB_OVERWRITE_DIR)/vite.config.ts ./web/
# < CORS >
# - Edit `cors.rb` to configure CORS
cors-setup:
	@echo "Edit ./api/config/initializers/cors.rb"
	@cp -r --verbose $(API_OVERWRITE_DIR)/cors.rb ./api/config/initializers/
	@echo "Add 'rack-cors' gem"
	@echo "Add 'rack-cors' gem: Edit Gemfile"
	@sed -i -e 's/# gem "rack-cors"/gem "rack-cors"/' ./api/Gemfile
	@echo "Add 'rack-cors' gem: Bundle install"
	@$(COMPOSE_CMD) $(COMPOSE_FILE_FLAG) run --rm $(API_SERVICE_NAME) bundle install
	@echo "Add 'rack-cors' gem: Rebuild images"
	@make build
# < db >
# - Create an empty database for development environments
db-setup:
	$(COMPOSE_CMD) $(COMPOSE_FILE_FLAG) run --rm $(API_SERVICE_NAME) rails db:create
# < ALL >
# - Execute all of `api-base-setup`, `web-base-set-up`, `db-setup` and `cors-setup`
all-setup:
	@make api-base-setup
	@make web-base-setup
	@make cors-setup
	@make db-setup


# [ BUILDERS ]
# - Build the images for all services
build:
	$(COMPOSE_CMD) $(COMPOSE_FILE_FLAG) build
# - Build the images for api service
api-build:
	$(COMPOSE_CMD) $(COMPOSE_FILE_FLAG) build $(API_SERVICE_NAME)
# - Build the images for db service
db-build:
	$(COMPOSE_CMD) $(COMPOSE_FILE_FLAG) build $(DB_SERVICE_NAME)
# - Build the images for web service
web-build:
	$(COMPOSE_CMD) $(COMPOSE_FILE_FLAG) build $(WEB_SERVICE_NAME)


# [ MAIN COMMANDS ]
# < SHELL OPENERS >
# - Open a bash session in an ephemeral api container (dev)
api-bash:
	$(COMPOSE_CMD) $(COMPOSE_FILE_FLAG) run --rm $(API_SERVICE_NAME) bash
# - Access the PostgreSQL shell in an ephemeral db container (dev)
db-shell:
	$(COMPOSE_CMD) $(COMPOSE_FILE_FLAG) run --rm $(DB_SERVICE_NAME) psql -h $(POSTGRES_HOST) -U $(POSTGRES_USER) -d $(DB_NAME)
# - Open a bash session in an ephemeral web container (dev)
web-bash:
	$(COMPOSE_CMD) $(COMPOSE_FILE_FLAG) run --rm --no-deps --service-ports web bash
# < OTHERS >
# - Start up the services (dev)
up:
	$(COMPOSE_CMD) $(COMPOSE_FILE_FLAG) up
# - Shut down and remove images
down:
	$(COMPOSE_CMD) down --rmi all


# [ CLEANERS ]
# - Delete all api-related files and reseed essential files
GEMFILE_CONTENT="source 'https://rubygems.org'\n\ngem 'rails', '$(RAILS_VER)'\n"
api-clean:
	@printf "[!] All files except those related to Docker will be deleted.\nAre you sure you want to continue? (y/n): "
	@read confirm; \
	if [ -z "$$confirm" ] || echo "$$confirm" | grep -Eq '^(Y|y|YES|yes|Yes|YEs|YeS|yEs|yeS)$$'; then \
		find ./api/ -mindepth 1 -exec rm -rf --verbose {} 2>/dev/null \; || true; \
		cp -r --verbose ./template/seed/api/* ./api/; \
		echo "Update the Gemfile according to the RAILS_VER in the .env file."; \
		printf $(GEMFILE_CONTENT) > ./api/Gemfile; \
	else \
		echo Canceled.; \
	fi
# - Delete related volumes
db-clean:
	docker volume rm -f $(PROJECT_NAME)_db-data
# - Delete all web-related files and reseed essential files
web-clean:
	@printf "[!] All files except those related to Docker will be deleted.\nAre you sure you want to continue? (y/n): "
	@read confirm; \
	if [ -z "$$confirm" ] || echo "$$confirm" | grep -Eq '^(Y|y|YES|yes|Yes|YEs|YeS|yEs|yeS)$$'; then \
		find ./web/ -mindepth 1 -exec rm -rf --verbose {} 2>/dev/null \; || true; \
		cp -r --verbose ./template/seed/web/* ./web/; \
	else \
		echo Canceled.; \
	fi


# [ STRONG CLEANERS ]
# - Delete all containers, images, volumes, and networks
all-docker-clean:
	@make down
	@docker container ls -a -q | xargs -r docker container rm -f || true
	@docker image ls -a -q | xargs -r docker image rm -f || true
	@docker volume ls -q | xargs -r docker volume rm -f || true
	@docker network prune -f || true
# - Execute all of `down`, `api-clean`, `db-clean` and `web-clean`
all-service-clean:
	@make down
	@make api-clean
	@make db-clean
	@make web-clean


# [ BACKUP TAKERS ]
BACKUP_DIR=./backup
# - Create partial-hard-link backups to ./backup/api/, designating candidates in ./apibackuplist
API_BACKUP_DIR=$(BACKUP_DIR)/api
API_BACKUP_PATHS_FILE=$(BACKUP_DIR)/apibackuplist
API_BACKUP_PATHS=$$(cat $(API_BACKUP_PATHS_FILE))
api-backup:
	@printf "\nTake hard-link backups to $(API_BACKUP_DIR), designating candidates in $(API_BACKUP_PATHS_FILE)\n"
	@cat $(API_BACKUP_PATHS_FILE)
	@for file in $(API_BACKUP_PATHS); do \
		ln -f "$$file" $(API_BACKUP_DIR); \
	done
# - Create partial-hard-link backups to ./backup/web/, designating candidates in ./webbackuplist
WEB_BACKUP_DIR=$(BACKUP_DIR)/web
WEB_BACKUP_PATHS_FILE=$(BACKUP_DIR)/webbackuplist
WEB_BACKUP_PATHS=$$(cat $(WEB_BACKUP_PATHS_FILE))
web-backup:
	@printf "\nTake hard-link backups to $(WEB_BACKUP_DIR), designating candidates in $($(WEB_BACKUP_PATHS_FILE))\n"
	@cat $(WEB_BACKUP_PATHS_FILE)
	@for file in $(WEB_BACKUP_PATHS); do \
		ln -f "$$file" $(WEB_BACKUP_DIR); \
	done


# [ TEST PROJECT ]
# - Create a User model and controller, and set up routing
API_TEMPLATE_DIR=./template/overwrite/test_project/api
SEEDS_TEMPLATE_FILE=$(API_TEMPLATE_DIR)/seeds-template.txt
CONTROLLER_TEMPLATE_FILE=$(API_TEMPLATE_DIR)/controller-template.txt
ROUTES_TEMPLATE_FILE=$(API_TEMPLATE_DIR)/routes-template.txt
MODEL_NAME=User
PLURL_NAME=Users
LOWER_PLURL_NAME=$$(echo $(PLURL_NAME) | tr [:upper:] [:lower:])
MODEL_CMD=rails g model $(MODEL_NAME) name:string email:string
CONTROLLER_CMD=rails g controller Api::V1::$(PLURL_NAME)
API_PATH=api/v1/$(LOWER_PLURL_NAME)
api-test-project: db
	@echo "Generate $(MODEL_NAME) model."
	$(COMPOSE_CMD) $(COMPOSE_FILE_FLAG) run --rm $(API_SERVICE_NAME) $(MODEL_CMD)
	@echo "Migrate $(MODEL_NAME) model."
	$(COMPOSE_CMD) $(COMPOSE_FILE_FLAG) run --rm $(API_SERVICE_NAME) rails db:migrate
	@echo "Edit db/seeds.rb"
	@cat $(SEEDS_TEMPLATE_FILE) >> ./api/db/seeds.rb
	@echo "Seed the database."
	$(COMPOSE_CMD) $(COMPOSE_FILE_FLAG) run --rm $(API_SERVICE_NAME) rails db:seed
	@echo "Generate $(PLURL_NAME) controller."
	$(COMPOSE_CMD) $(COMPOSE_FILE_FLAG) run --rm $(API_SERVICE_NAME) $(CONTROLLER_CMD)
	@echo "Edit $(LOWER_PLURL_NAME)_controller.rb"
	@cat $(CONTROLLER_TEMPLATE_FILE) > ./api/app/controllers/$(API_PATH)_controller.rb
	@echo "Edit routes.rb"
	@cat $(ROUTES_TEMPLATE_FILE) > ./api/config/routes.rb
	@echo "Edit production.rb"
	@cat $(ROUTES_TEMPLATE_FILE) > ./api/config/environments/production.rb
	@echo "...Complete."
	@echo "Please run 'make up' to start the services. Then, access 'http://localhost:$(API_PORT)/$(API_PATH)' in your browser."
# - Overwrite ./web/src/App.tsx so that you can check accessiblity to the API, arranging the `Call API` button in DOM
WEB_TEMPLATE_DIR=./template/overwrite/test_project/web
web-test-project:
	@echo "Overwrite ./web/src/App.tsx"
	@cp -r --verbose $(WEB_TEMPLATE_DIR)/App.tsx ./web/src/
	@echo "Please run 'make up' to start the services. Then, access 'http://localhost:$(WEB_PORT)' in your browser."
# < ALL >
# - Execute both of `api-test-project` and `web-test-project`
test-project:
	@make api-test-project
	@make web-test-project


# [ OTHERS ]
# - Show help
help:
	@echo "Available commands:"
	@grep -hE '^- [a-zA-Z_\.-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	awk 'BEGIN {FS=":.*?## "}; {printf "%-20s %s\n", $$1, $$2}' | \
	sort


# Mark the targets with comments for help display
- dcom_context:	    	## : Set up the current directory as the Docker Compose context
- api-launch:					## : Run `rails new` in an ephemeral api container
- web-launch:					## : Create a new React x Typescript x swc app with Vite
- all-launch:					## : Execute both of `api-launch` and `web-launch`

- api-base-setup:			## : Overwrite files with the user template in ./template/overwrite/api/
- web-base-setup:			## : Overwrite files with the user template in ./template/overwrite/web/
- cors-setup:					## : Edit `cors.rb` to configure CORS
- db-setup:						## : Create an empty database for development environments
- all-setup:					## : Execute all of `api-base-setup`, `web-base-set-up`, `db-setup` and `cors-setup`

- build:							## : Build the images for all services
- api-build:					## : Build the images for api service
- db-build:						## : Build the images for db service
- web-build:					## : Build the images for web service

- api-bash:						## : Open a bash session in an ephemeral api container (dev)
- db-shell:						## : Access the PostgreSQL shell in an ephemeral db container (dev)
- web-bash:						## : Open a bash session in an ephemeral web container (dev)
- up:									## : Start up the services (dev)
- down:								## : Shut down and remove images

- api-clean:					## : Delete all api-related files and reseed essential files
- db-clean:						## : Delete related volumes
- web-clean:					## : Delete all web-related files and reseed essential files
- all-docker-clean:		## : Delete all containers, images, volumes, and networks
- all-service-clean:	## : Execute all of `down`, `api-clean`, `db-clean` and `web-clean`

- api-backup:					## : Create partial-hard-link backups to ./backup/api/, designating candidates in ./apibackuplist
- web-backup:					## : Create partial-hard-link backups to ./backup/web/, designating candidates in ./webbackuplist

- api-test-project:		## : Create a User model and controller, and set up routing
- web-test-project:		## : Overwrite ./web/src/App.tsx so that you can check accessiblity to the API, arranging the `Call API` button in DOM
- test-project:				## : Execute both of `api-test-project` and `web-test-project`
- help:								## : Show help