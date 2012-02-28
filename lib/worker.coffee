# Open Cluster for Chess Engine Testing 0.0.1
# Copyright (C) 2012 Vincent Ollivier
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

os = require('os')
fs = require('fs')
http  = require('http')
util  = require('util')
spawn = require('child_process').spawn
exec = require('child_process').exec
querystring = require('querystring')
events = require('events')

config =
    'host': 'localhost'
    'port': 3838
    'debug': false
    'cli': 'cutechess-cli'
    'args':
        'fcp': 'fcp'
        'scp': 'scp'
        'both': 'both'

platform = os.platform() + '-' + os.arch()

delayCache = {}
maxDelay = 1 * 64 * 1000 # 64 seconds between server query

cachePath = process.env.XDG_CACHE_HOME + '/occet/worker'
dataPath = process.env.XDG_DATA_HOME + '/occet/worker'

clearDelay = (k) ->
    delete delayCache[k]
    return

getDelay = (k) ->
    return delayCache[k] = 125 unless delayCache[k]?
    return if delayCache[k] < maxDelay then delayCache[k] *= 2 else maxDelay

requestJob = ->
    util.log('Requested a new job')
    query =
        'platform': platform
    options =
        'host': config.host
        'port': config.port
        'path': '/jobs?' + querystring.stringify(query)
        'method': 'GET'
    req = http.request options, (res) ->
        res.setEncoding('utf8')
        content = ''
        res.on 'data', (data) ->
            content += data
            return
        res.on 'end', ->
            job = null
            try
                job = JSON.parse(content.toString()) if content.length
            catch err
                console.error(err)
            if job?
                util.log('Got new job #' + job.id)
                clearDelay('request')
                startJob(job)
            else
                delay = getDelay('request')
                util.log("Got nothing, retrying in #{delay}ms")
                setTimeout(requestJob, delay)
            return
        return
    req.on 'error', (err) ->
        delay = getDelay('request')
        util.log("Got an error when requesting a job, retrying in #{delay}ms")
        console.error(err)
        setTimeout(requestJob, delay)
        return
    req.end()
    return

startJob = (job) ->
    timeout = 1000 # 1 second
    args = []
    args.push('-site', os.hostname())
    args.push('-debug') if config.debug
    for option, arg of job.config
        # Translate option value if needed
        arg = "#{dataPath}/#{arg}" if option is 'pgnin'
        arg = "#{cachePath}/#{arg}" if option is 'pgnout'

        # Translate option name if needed
        option = config.args[option] if config.args[option]?

        # Add option command arguments
        args.push "-#{option}"
        switch (typeof arg)
            when 'object' then args.push("#{k}=#{v}") for k, v of arg
            else args.push(arg)

        # Get values for command timeout
        switch option
            when 'each', 'both'
                [moves, time, incr] = arg.tc.split(/[^\d.]/).map (x) ->
                    parseFloat(x, 10)
                incr = 0 unless incr?
                ply = 200 # Exaggerated mean number of ply in a game
                # Approximate duration of a game
                timeout *= ply * (incr + time / moves)
            when 'games'
                # Multiplied by the number of games
                timeout *= arg

    worker = spawn(config.cli, args) # Start worker
    timer = setTimeout (-> worker.kill()), timeout # Set worker timeout

    debugPath = "/tmp/occet-worker-#{job.id}.debug"
    debug = fs.createWriteStream debugPath if config.debug

    util.log("Started job ##{job.id} with pid: #{worker.pid}")

    worker.stderr.on 'data', (data) ->
        console.error('worker stderr: ' + data)
        return

    worker.stdout.on 'data', (data) ->
        debug.write(data) if config.debug
        return

    worker.stdout.on 'end', (data) ->
        debug.end() if config.debug
        return

    worker.on 'exit', (code, signal) ->
        clearTimeout(timer)
        worker.stdout.end()
        if code?
            util.log("Job ##{job.id} ended with code: #{code}")
        if signal?
            util.log("Job ##{job.id} terminated by signal: #{signal}")
        sendResult(job.id, job.config.pgnout)
        requestJob()
        return
    return

sendResult = (id, filename) ->
    path = "#{cachePath}/#{filename}"
    fs.readFile path, 'utf8', (err, data) ->
        return if err?.code is 'ENOENT' # Nothing to send
        throw err if err?

        body = querystring.stringify
            'pgn': data

        options =
            'host': config.host
            'port': config.port
            'path': '/jobs/' + id
            'method': 'PUT'
            'headers':
                'Content-Type': 'application/x-www-form-urlencoded'
                'Content-Length': body.length

        req = http.request options, (res) ->
            res.setEncoding('utf8')
            res.on 'end', ->
                # TODO: Check HTTP status code
                util.log("Job ##{id} results saved")
                clearDelay('results' + id)
                fs.unlink(path)
                return
            return
        req.on 'error', (err) ->
            delay = getDelay('results' + id)
            util.log "Got an error when sending job ##{id} results, " +
                     "retrying in #{delay}ms"
            console.error(err)
            setTimeout(sendResult, delay, id, filename)
            return
        req.end(body)
        return
    return


# Public functions

exports.events = new events.EventEmitter()

exports.init = (host, port, debug) ->
    # TODO: config[k] = v for k, v of params..
    config.host = host
    config.port = port
    config.debug = debug
    exec "#{config.cli} --version", (error, stdout, stderr) ->
        [major, minor, build] = stdout.split('\n')[0].split(' ')[1].split('.')
        switch config.cli
            when 'cutechess-cli'
                if major > 0 or minor > 4
                    config.args =
                        'fcp': 'engine'
                        'scp': 'engine'
                        'both': 'each'
        exports.events.emit('ready')
        return
    return

exports.run = (n) ->
    for i in [1..n]
        setTimeout(requestJob, i * 500)
    return
