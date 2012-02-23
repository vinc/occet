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
