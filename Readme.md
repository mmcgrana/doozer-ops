# doozer-ops

Performance and operations evaluation of Doozer.


## Usage

Ensure that `doozerd` is in your path.

Install `doozer-ops` dependencies:

    $ bundle install

Start a local, 5 node doozer cluster:

    $ bin/local5

Benchmark, writing, reading, and syncing a 1000 key dataset, with a pipeline width of 5:

    $ bin/write 1000 5 --verbose
    $ bin/read 1000 5 --verbose
    $ bin/sink --verbose
