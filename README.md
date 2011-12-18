Open Cluster for Chess Engine Testing
=====================================

Installation
------------

    git clone https://github.com/vinc/occet.git
    cd occet
    sudo npm install --global


Usage
-----

To run the server do:

    occet-server

To add engines and jobs to the server do:

    occet-client --host 127.0.0.1 add-engine --name "Purple Haze 2.0.2" --cmd purplehaze
    occet-client --host 127.0.0.1 add-engine --name "TSCP 1.8.1" --cmd tscp
    occet-client --host 127.0.0.1 add-job --fcp purplehaze --scp tscp -t 10 -i 1 --games 100

To run a worker (on every CPU):

    occet-worker --host 127.0.0.1
