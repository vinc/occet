Open Cluster for Chess Engine Testing
=====================================

Every new version of a modern chess engine should be tested against another
engines to evaluate any improvements. To be statistically relevant this
evaluation needs tens of thousands of games. This takes a lot of time,
or a lot of computers.

OCCET is simple middleware for distributing jobs across any number of
computers over HTTP. Each job, executed by a worker, consists of a wrapper
around cutechess-cli, playing a number of games against two chess engines.

The server collects PGN results which are useful to estimate Elo ratings
between the engines using tools like bayeselo.

OCCET is currently on early alpha stage.


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

The following software must be installed on each computer running the worker:

* [cutechess-cli](http://ajonsson.kapsi.fi/cutechess.html)


Usage
-----

To run the server (listening on port 3838):

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
