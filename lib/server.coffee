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

fs = require('fs')
util = require('util')
querystring = require('querystring')

module.exports = (app, express) ->

    app.configure ->
        app.use(express.bodyParser())
        app.use(express.methodOverride())
        app.use(app.router)
        return

    app.configure 'development', ->
        app.use express.errorHandler
            dumpExceptions: true,
            showStack: true
        return

    app.configure 'production', ->
        app.use express.errorHandler
        return

    app.resultsPath = '.'
    app.configFile = './config.json'
    engines = {}
    counter = 0
    pool = []

    app.init = (callback) ->
        loadConfig (err) ->
            err = null if err?.code is 'ENOENT'
            callback(err)
            return
        return

    loadConfig = (callback) ->
        fs.readFile app.configFile, (err, data) ->
            unless err?
                config = JSON.parse(data)
                engines = config.engines
            callback(err)
            return
        return

    saveConfig = (callback, res = []) ->
        config =
            "engines": engines
        data = JSON.stringify(config)
        fs.writeFile app.configFile, data, (err) ->
            callback(err, res)
            return
        return

    putJob = (games, tc, fcp, scp, book) ->
        return null unless engines[fcp]? and engines[scp]?
        id = ++counter
        job =
            'id': id
            'config':
                'games': games
                'pgnout': "games-#{id}.pgn"
                'both':
                    'tc': tc
                'fcp': engines[fcp]
                'scp': engines[scp]
        job.config.pgnin = book if book?
        pool.push(job)
        return id

    getJob = ->
        return if pool.length then pool.shift() else null

    addEngine = (engine, callback) ->
        res =
            'modified': engines[engine.cmd]?
        engines[engine.cmd] = engine
        saveConfig(callback, res)
        return

    flushJobs = ->
        pool = []
        return



    # Client

    # Delete all jobs
    app.delete '/jobs', (req, res) ->
        flushJobs()
        addr = req.client.remoteAddress
        #platform = req.param('platform')
        util.log("Jobs pool flushed by #{addr}")
        res.end(200)
        return

    # Create a new job
    app.post '/jobs', (req, res) ->
        games = req.param('games')
        tc = req.param('tc')
        fcp = req.param('fcp')
        scp = req.param('scp')
        book = req.param('book', null)
        id = putJob(games, tc, fcp, scp, book)
        if id?
            util.log("Job ##{id} added")
            res.json(id, 201)
        else
            res.json(null, 404) # TODO: Find the correct HTTP status code
        return

    # Create a new engine
    app.post '/engines', (req, res) ->
        name = req.param('name')
        cmd = req.param('cmd')
        proto = req.param('proto')
        engine =
            'name': name
            'cmd': cmd
            'proto': proto
        addEngine engine, (err, res) ->
            throw err if err?
            if res.modified
                util.log("Engine '#{name}' modified")
                res.send(200)
            else
                util.log("Engine '#{name}' created")
                res.send(201)
            return
        return


    # Worker

    # Update finished job
    app.put '/jobs/:id', (req, res) ->
        addr = req.client.remoteAddress
        id = req.param('id')
        pgn = req.param('pgn')
        path = "#{app.resultsPath}/games-#{id}.pgn"
        util.log("Job ##{id} results received from #{addr}")
        fs.writeFile path, pgn, (err) ->
            throw err if err
            util.log("Job ##{id} results saved to '#{path}'")
            res.end("Job ##{id} results saved") # TODO: Change this, not RESTful
            return
        return

    # Send new job to worker
    app.get '/jobs', (req, res) ->
        addr = req.client.remoteAddress
        platform = req.param('platform')
        job = getJob()
        res.json(job)
        res.end() # TODO: Optional?
        if job?
            util.log("Job ##{job.id} sent to #{addr} (#{platform})")
        else
            util.log("No jobs left for #{addr} (#{platform})")
        return

    return
