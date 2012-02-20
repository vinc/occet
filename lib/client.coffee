#!/usr/bin/env node

http  = require('http')
querystring = require('querystring')

config = {}

exports.init = (host, port) ->
    config.host = host
    config.port = port
    return

sendRequest = (path, method = 'GET', data = null) ->
    options =
        'host': config.host
        'port': config.port
        'path': path
        'method': method
    body = querystring.stringify(data)
    if data?
        options.headers =
            'Content-Type': 'application/x-www-form-urlencoded'
            'Content-Length': body.length
    req = http.request options, (res) ->
        res.setEncoding('utf8')
        res.on 'data', (chunk) ->
            console.log(chunk)
            return
        return
    req.on 'error', (err) ->
        console.error('problem with request: ' + err.message)
        return
    req.end(body)
    return

addJob = (job) ->
    sendRequest('/jobs', 'POST', job)
    return

exports.addJobs = (job, n) ->
    for i in [1..n]
        setTimeout(addJob, i * 50, job)
    return

exports.addEngine = (engine) ->
    sendRequest('/engines', 'POST', engine)
    return

exports.flushJobs = ->
    sendRequest('/jobs', 'DELETE')
    return
