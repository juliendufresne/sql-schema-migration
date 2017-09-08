Install on Docker
=================

This page describes how to install the app on a docker environment. For other environment, visit [the main installation page](docs/INSTALL.md).

Requirements
------------

* latest docker community edition (CE) version - [link](https://docs.docker.com/engine/installation/) 
* (non mac users) latest docker-compose version - [link](https://docs.docker.com/compose/install/) 
* GNU make

Install
-------

Once you have every requirements, simply run:

```bash
./configure docker && make install
```

Usage
-----

| command                   | alternative                           | description            |
| ------------------------- | ------------------------------------- | ---------------------- |
| `bin/php bin/console ...` | `docker-compose run app bin/console`  | symfony console        |
| `bin/composer ...`        | `docker-compose run app composer ...` | run composer commands  |
