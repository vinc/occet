#!/usr/bin/env coffee

# Copyright (C) 2012 Vincent Ollivier
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

os = require('os')
fs = require('fs')
program = require('commander')
worker = require('../lib/worker')

program
    .version('0.0.1')
    .option('--debug', 'Run worker in debug mode')
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

fs.writeFileSync lockFile, process.pid


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
worker.init(program.host, program.port, program.debug)
worker.events.on 'ready', ->
    worker.run(program.concurrency)
    return

process.on 'exit', ->
    fs.unlinkSync(lockFile) # Remove lockFile
