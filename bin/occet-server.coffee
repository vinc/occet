#!/usr/bin/env coffee

fs = require('fs')
express = require('express')
app = module.exports = express.createServer()

require('../lib/server')(app, express)

program = require('commander')
program
    .version('0.0.1')
    .option('--port <port>', 'Listen on <port>', Number, 3838)
    .parse(process.argv)

isDir = (path) ->
    try
        return true if fs.statSync(path).isDirectory()
    catch err
        return false if err.code is 'ENOENT'
    console.error("occet-server: error stating '#{path}'")
    process.exit(1)
    return

# Store results in '~/.local/share/occet/server/results/*'
path = process.env.XDG_DATA_HOME
unless isDir(path)
    console.error("occet-server: cannot access '#{path}'")
    process.exit(1)
for dir in ['occet', 'server', 'results']
    path += '/' + dir
    fs.mkdirSync(path, 0700) unless isDir(path)
i = 0
continue while isDir(app.resultsPath = path + '/' + i++)
fs.mkdirSync(app.resultsPath, 0700)

app.listen(program.port)
