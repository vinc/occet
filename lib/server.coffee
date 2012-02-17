# Open Cluster for Chess Engines Testing

fs = require('fs')
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
                #counter = config.counter
            callback(err)
            return
        return

    saveConfig = (callback) ->
        config =
            "engines": engines
            #"counter": counter
        data = JSON.stringify(config)
        fs.writeFile app.configFile, data, (err) ->
            callback(err)
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
        engines[engine.cmd] = engine
        saveConfig(callback)
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
        console.log("Jobs pool flushed by #{addr}")
        res.end()
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
            msg = "Job ##{id} added"
            res.send(msg)
            console.log(msg)
        else
            res.send(403)
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
        addEngine engine, (err) ->
            throw err if err?
            msg = "Engine '#{name}' added"
            res.send(msg)
            console.log(msg)
            return
        return


    # Worker

    # Update finished job
    app.put '/jobs/:id', (req, res) ->
        addr = req.client.remoteAddress
        id = req.param('id')
        pgn = req.param('pgn')
        path = "#{app.resultsPath}/games-#{id}.pgn"
        console.log("Job ##{id} results received from #{addr}")
        fs.writeFile path, pgn, (err) ->
            throw err if err
            console.log("Job ##{id} results saved to '#{path}'")
            res.end("Job ##{id} results saved")
            return
        return

    # Send new job to worker
    app.get '/jobs', (req, res) ->
        addr = req.client.remoteAddress
        platform = req.param('platform')
        job = getJob()
        if job?
            res.json(job)
            console.log("Job ##{job.id} sent to #{addr} (#{platform})")
        else
            res.json(null)
            console.warn("No jobs left for #{addr} (#{platform})")
            res.end()
        return

    return
