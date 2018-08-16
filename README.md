# skilld-docker-container

---

* [Overview](#overview)
* [Instructions](#instructions)
* [Usage](#usage)

## Overview

This branch is for make contrib tasks easier.

## Instructions

Supported PHP versions: 7.x and 5.6.x.

1\. Install docker for <a href="https://docs.docker.com/engine/installation/" target="_blank">Linux</a>, <a href="https://docs.docker.com/engine/installation/mac" target="_blank">Mac OS X</a> or <a href="https://docs.docker.com/engine/installation/windows" target="_blank">Windows</a>. __For Mac and Windows make sure you're installing native docker app version 1.12, not docker toolbox.__

For Linux install <a href="https://docs.docker.com/compose/install/" target="_blank">docker compose</a>

2\. Copy __\.env\.default__ to __\.env__

  2\.1\. Set _COMPOSE_PROJECT_NAME_ variable with value you need

  2\.2\. Change _IMAGE_PHP_ in case you need another one

3\. Copy __docker-compose\.override\.yml\.default__ to __docker-compose\.override\.yml__

  This file is used to overwrite container settings and/or add your own. See https://docs.docker.com/compose/extends/#/understanding-multiple-compose-files for details.

4\. Run `make`

## Usage

* `make` - Install project.
* `make clean` - totally remove project build folder, docker containers and network.
* `make reinstall` - rebuild & reinstall site.
* `make si` - reinstall site.
* `make info` - Show project services IP addresses.
* `make exec` - docker exec into php container.
* `make exec0` - docker exec into php container as root.
* `make dev` - Devel + kint setup, and config for Twig debug mode.
