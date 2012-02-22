Open Cluster for Chess Engine Testing
=====================================

Installation
------------

Before building OCCET, the following software should be installed:

* [coffee](http://coffeescript.org/)
* [git](http://git-scm.com/)
* [node](http://nodejs.org/)
* [npm](http://npmjs.org/)

To download, build and install OCCET:

    $ git clone https://github.com/vinc/occet.git
    $ cd occet
    $ sudo npm install --global


Usage
-----

To run the server:

    $ occet-server

To add engines and jobs to the server:

    $ occet-client --host 127.0.0.1 \
        add-engine --name "Purple Haze 2.0.2" --cmd purplehaze
    $ occet-client --host 127.0.0.1 \
        add-engine --name "TSCP 1.8.1" --cmd tscp
    $ occet-client --host 127.0.0.1 \
        add-job --fcp purplehaze --scp tscp -t 10 -i 1 --games 100

To run a worker (on every CPU):

    $ occet-worker --host 127.0.0.1


License
-------

Copyright (C) 2012 Vincent Ollivier, released under GNU GPL License v3
