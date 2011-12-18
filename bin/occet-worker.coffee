#!/usr/bin/env coffee

os = require('os')
program = require('commander')
worker = require('../lib/worker')

program
    .version('0.0.1')
    .option('--host <host>', 'Connect to <host>', 'localhost')
    .option('--port <port>', 'Connect to <port>', Number, 3838)
    .option('-c, --concurrency <n>', 'Use <n> CPUs', Number, os.cpus().length)
    .parse(process.argv)

worker.init(program.host, program.port)
worker.run(program.concurrency)
