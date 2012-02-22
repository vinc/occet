#!/usr/bin/env coffee

os = require('os')
fs = require('fs')
program = require('commander')
worker = require('../lib/worker')

program
    .version('0.0.1')
    .option('--host <host>', 'Connect to <host>', 'localhost')
    .option('-p, --port <port>', 'Connect to <port>', Number, 3838)
    .option('-c, --concurrency <n>', 'Use <n> CPUs', Number, os.cpus().length)
    .parse(process.argv)

process.title = "occet-worker --concurrency #{program.concurrency}"

lockFile = '/tmp/occet-worker.lock'
try
    # Check lockFile
    pid = parseInt(fs.readFileSync(lockFile, 'utf8').trim())

    # Check process
    process.kill(pid, 0)

    msg = "Remove '#{lockFile}' if a worker is not already running."
    console.error(msg)
    process.exit(1)
catch err
    switch err.code
        # LockFile not found
        when 'ENOENT' then

        # Process not found
        when 'ESRCH' then fs.unlinkSync(lockFile) # Remove lockFile

        else throw err

fs.writeFileSync lockFile, process.pid, 0


isDir = (path) ->
    try
        return fs.statSync(path).isDirectory()
    catch err
        return false if err.code is 'ENOENT'
        throw err
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

process.on 'exit', ->
    fs.unlinkSync(lockFile) # Remove lockFile
