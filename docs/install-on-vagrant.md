Install on Vagrant
==================

This page describes how to install the app on a vagrant environment. For other environment, visit [the main installation page](docs/INSTALL.md).

Requirements
------------

* latest virtualbox version with extension pack - [link](https://www.virtualbox.org/wiki/Downloads)
* latest vagrant version - [link](https://www.vagrantup.com/downloads.html)
* GNU make

Install
-------

Once you have every requirements, simply run:

```bash
./configure vagrant && make install
```

Usage
-----

| command            | description            |
| ------------------ | ---------------------- |
| `vagrant ssh app`  | access app VM          |
