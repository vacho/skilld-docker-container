.PHONY: all up down prepare install si exec info

# Read project name from .env file
$(shell false | cp -i \.env.default \.env 2>/dev/null)
$(shell false | cp -i \.\/docker\/docker-compose\.override\.yml\.default \.\/docker\/docker-compose\.override\.yml 2>/dev/null)
include .env

# Get local values only once.
LOCAL_UID := $(shell id -u)
LOCAL_GID := $(shell id -g)

# Evaluate recursively.
CUID ?= $(LOCAL_UID)
CGID ?= $(LOCAL_GID)

COMPOSE_NET_NAME := $(COMPOSE_PROJECT_NAME)_front

php = docker-compose exec -T --user $(CUID):$(CGID) php time ${1}
php-0 = docker-compose exec -T php time ${1}

## Full site install from the scratch
all: | prepare install si info

prepare:
	mkdir -p mysql drupal
	make -s down
	make -s up
	git clone https://git.drupal.org/project/drupal.git drupal
	$(call php-0, apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community git)
	$(call php-0, kill -USR2 1)
	$(call php, composer global require -o --update-no-dev --no-suggest "hirak/prestissimo:^0.3")

## Install site
install:
	$(call php, composer install --prefer-dist -o --no-dev)

## Reinstall site
si:
	@echo "Installing Drupal"
	$(call php, drush si --db-url=$(DB_URL) --account-pass=admin -y --site-name="$(SITE_NAME)" --site-mail="$(SITE_MAIL)")
	make -s info

## Project's containers information
info:
ifeq ($(shell docker inspect --format="{{ .State.Running }}" $(COMPOSE_PROJECT_NAME)_web 2> /dev/null),true)
	@echo Project http://$(shell docker inspect --format='{{(index .NetworkSettings.Networks "$(COMPOSE_NET_NAME)").IPAddress}}' $(COMPOSE_PROJECT_NAME)_web)
endif
ifeq ($(shell docker inspect --format="{{ .State.Running }}" $(COMPOSE_PROJECT_NAME)_mail 2> /dev/null),true)
	@echo Mailhog http://$(shell docker inspect --format='{{(index .NetworkSettings.Networks "$(COMPOSE_NET_NAME)").IPAddress}}' $(COMPOSE_PROJECT_NAME)_mail):8025
endif
ifeq ($(shell docker inspect --format="{{ .State.Running }}" $(COMPOSE_PROJECT_NAME)_adminer 2> /dev/null),true)
	@echo Adminer http://$(shell docker inspect --format='{{(index .NetworkSettings.Networks "$(COMPOSE_NET_NAME)").IPAddress}}' $(COMPOSE_PROJECT_NAME)_adminer)
endif


## Run shell in PHP container as CUID:CGID user
exec:
	docker-compose exec --user $(CUID):$(CGID) php ash

## Run shel in PHP container as root
exec0:
	docker-compose exec php ash

## Up
up: net
	@echo "Updating containers..."
	docker-compose pull
	@echo "Build and run containers..."
	docker-compose up -d --remove-orphans

## Down
down:
	@echo "Removing network & containers for $(COMPOSE_PROJECT_NAME)"
	@docker-compose down -v --remove-orphans

## Totally remove project build folder, docker containers and network
clean: DIRS := drupal mysql
clean: info down
	@for i in $(DIRS); do if [ -d "$$i" ]; then echo "Removing $$i..."; docker run --rm -v $(shell pwd):/mnt $(IMAGE_PHP) sh -c "rm -rf /mnt/$$i"; fi; done

net:
ifeq ($(shell docker network ls -q -f Name=$(COMPOSE_NET_NAME)),)
	docker network create $(COMPOSE_NET_NAME)
	make -s iprange
endif

iprange:
	$(shell grep -q -F 'IPRANGE=' .env || printf "\nIPRANGE=$(shell docker network inspect $(COMPOSE_NET_NAME) --format '{{(index .IPAM.Config 0).Subnet}}')" >> .env)



dev:
	@echo "Dev tasks..."
	$(call php, chmod -R 777 sites/default/files)
	$(call php, cp sites/default/default.services.yml sites/default/services.yml)
	$(call php, cp sites/example.settings.local.php sites/default/settings.local.php)
	$(call php, drush en devel devel_generate kint -y)
	$(call php, drush pm-uninstall dynamic_page_cache page_cache -y)
