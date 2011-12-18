# Open Cluster for Chess Engines Testing

os = require('os')
fs = require('fs')
http  = require('http')
util  = require('util')
spawn = require('child_process').spawn
querystring = require('querystring')

useChroot = false
workingPath = if useChroot then 'chroot' else '.'

options = {}

platform = os.platform() + '-' + os.arch()

delayCache = {}
maxDelay = 1 * 60 * 1000 # Don't wait more than 1 minute

clearDelay = (k) ->
    delete delayCache[k]
    return

getDelay = (k) ->
    return delayCache[k] = 125 unless delayCache[k]?
    return if delayCache[k] < maxDelay then delayCache[k] *= 2 else maxDelay

requestJob = ->
    console.log('Requested a new job')
    options.path = '/job/get/' + platform
    options.metod = 'GET'
    options.headers = {}
    req = http.get options, (res) ->
        res.on 'data', (data) ->
            job = JSON.parse(data.toString())
            if job?
                console.log('Got new job #' + job.id)
                #console.log(config)
                clearDelay('request')
                startJob(job)
            else
                delay = getDelay('request')
                console.warn("Got nothing, retrying in #{delay}ms")
                setTimeout(requestJob, delay)
            return
        return
    req.on 'error', (err) -> 
        delay = getDelay('request')
        msg = "Got an error when requesting a job, retrying in #{delay}ms"
        console.error(msg)
        console.error('Error: ' + err.message)
        setTimeout(requestJob, delay)
        return
    return

startJob = (job) ->
    args = []
    args.push('chroot', 'cutechess-cli') if useChroot
    args.push('-site', os.hostname())
    for option, arg of job.config
        args.push "-#{option}"
        switch (typeof arg)
            when 'object' then args.push("#{k}=#{v}") for k, v of arg
            else args.push(arg)

    cmd = if useChroot then 'chroot' else 'cutechess-cli'
    worker = spawn(cmd, args)

    console.log('Started job #' + job.id + ' with pid: ' + worker.pid)

    worker.stderr.on 'data', (data) ->
        console.log('stderr: ' + data)
        return

    worker.stdout.on 'data', (data) ->
        console.log('stdout: ' + data)
        return

    worker.on 'exit', (code) ->
        console.log('Job #' + job.id + ' ended with code: ' + code)
        sendResult(job.id, job.config.pgnout)
        requestJob() if code is 0
        return
    return

sendResult = (id, filename) ->
    path = "#{workingPath}/#{filename}"
    fs.readFile path, 'utf8', (err, data) ->
        throw err if err
        result =
            'pgn': data
        body = querystring.stringify(result)

        options.path = '/job/' + id
        options.method = 'POST'
        options.headers =
          'Content-Type': 'application/x-www-form-urlencoded'
          'Content-Length': body.length

        req = http.request options, (res) ->
            res.setEncoding('utf8')
            res.on 'data', (data) ->
                console.log(data)
                clearDelay('results' + id)
                fs.unlink(path)
                return
            return
        req.on 'error', (err) ->
            delay = getDelay('results' + id)
            msg = "Got an error when sending job ##{id} results, " + 
                  "retrying in #{delay}ms"
            console.error(msg)
            console.error(err)
            setTimeout(sendResult, delay, id, filename)
        req.end(body)
        return
    return


# Public functions

exports.init = (host, port) ->
    options.host = host
    options.port = port
    return

exports.run = (n) ->
    for i in [1..n]
        setTimeout(requestJob, i * 500)
    return
