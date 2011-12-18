#!/usr/bin/env coffee

express = require('express')
app = module.exports = express.createServer()

require('../lib/server')(app, express)

program = require('commander')
program
    .version('0.0.1')
    .option('--port <port>', 'Listen on <port>', Number, 3838)
    .parse(process.argv)

app.listen(program.port)
