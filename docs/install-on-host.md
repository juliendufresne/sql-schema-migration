Install on Host
===============

This page describes how to install the app on your host environment. For other environment, visit [the main installation page](docs/INSTALL.md).

Requirements
------------

* PHP 7.1 with extensions: bcmath curl mbstring xml
* GNU make

Install
-------

Once you have every requirements, simply run:

```bash
./configure raw && make install
```

Configuration
-------------

To install every software by hand, the easiest thing to do is to have a look at how we [provision vagrant softwares](.provision/vagrant).  
This should be pretty straightforward.
