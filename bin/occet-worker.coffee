#!/usr/bin/env coffee

os = require('os')
fs = require('fs')
program = require('commander')
worker = require('../lib/worker')

program
    .version('0.0.1')
    .option('--host <host>', 'Connect to <host>', 'localhost')
    .option('--port <port>', 'Connect to <port>', Number, 3838)
    .option('-c, --concurrency <n>', 'Use <n> CPUs', Number, os.cpus().length)
    .parse(process.argv)

isDir = (path) ->
    try
        return true if fs.statSync(path).isDirectory()
    catch err
        return false if err.code is 'ENOENT'
    console.error("occet-worker: error stating '#{path}'")
    process.exit(1)
    return

# Store session data in '~/.cache/occet/worker'
path = process.env.XDG_CACHE_HOME
unless isDir(path)
    console.error("occet-worker: cannot access '#{path}'")
    process.exit(1)
path += '/occet'
fs.mkdirSync(path, 0700) unless isDir(path)
path += '/worker'
if isDir(path) # Remove previous data
    for file in fs.readdirSync(path)
        fs.unlinkSync("#{path}/#{file}")
    fs.rmdirSync(path)
fs.mkdirSync(path, 0700)

# Store shared data in '~/.local/share/occet/worker'
path = process.env.XDG_DATA_HOME
unless isDir(path)
    console.error("occet-worker: cannot access '#{path}'")
    process.exit(1)
for dir in ['occet', 'worker']
    path += '/' + dir
    fs.mkdirSync(path, 0700) unless isDir(path)

# Start worker
worker.init(program.host, program.port)
worker.events.on 'ready', ->
    worker.run(program.concurrency)
    return
