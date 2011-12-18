#!/usr/bin/env node

http  = require('http')
querystring = require('querystring')

options = {}

exports.init = (host, port) ->
    options.host = host 
    options.port = port
    return

sendRequest = (path) ->
    options.path = path 
    req = http.get options, (res) ->
        res.setEncoding('utf8')
        res.on 'data', (data) ->
            console.log(data)
            return
        return
    req.on 'error', (err) ->
        console.error('problem with request: ' + err.message)
        return
    req.end()
    return

addJob = (job) ->
    path = '/job/new?' + querystring.stringify(job)
    sendRequest(path)
    return

exports.addJobs = (job, n) ->
    for i in [1..n]
        setTimeout(addJob, i * 1000, job)
    return

exports.addEngine = (engine) ->
    path = '/engine/new?' + querystring.stringify(engine)
    sendRequest(path)
    return
