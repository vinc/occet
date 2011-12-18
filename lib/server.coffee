# Open Cluster for Chess Engines Testing

fs = require('fs')

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
    
    resultsPath = 'results'
    # TODO Add a command line option for this.
    # TODO Should it be synchronous, even if the callback will be executed
    #      way before any results are saved?
    fs.stat resultsPath, (err, stats) ->
        if err?
            switch err.code
                when 'ENOENT'
                    msg = "Invalid results path: " +
                          "no such file or directory '#{resultsPath}'"
                    console.error(msg)
                else console.error(err.message)
            process.exit(73) # EX_CANTCREAT
        unless stats.isDirectory()
            msg = "Invalid results path: " +
                  "not a directory '#{resultsPath}'"
            console.error(msg)
            process.exit(73) # EX_CANTCREAT
        return

    engines = {}

    counter = 0
    pool = []

    putJob = (games, tc, fcp, scp) ->
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
        pool.push(job)
        return id

    getJob = ->
        return if pool.length then pool.shift() else null

    app.post '/job/:id', (req, res) ->
        addr = req.client.remoteAddress
        id = req.param('id')
        pgn = req.body.pgn
        path = "#{resultsPath}/games-#{id}.pgn"
        console.log("Job ##{id} results received from #{addr}")
        fs.writeFile path, pgn, (err) ->
            throw err if err
            console.log("Job ##{id} results saved to '#{path}'")
            res.end("Job ##{id} results saved")
            return
        return

    app.get '/job/get/:platform?', (req, res) ->
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


    # TODO Either use GET or POST to add engines or jobs

    app.get '/job/new', (req, res) ->
        games = req.param('games')
        tc = req.param('tc')
        fcp = req.param('fcp')
        scp = req.param('scp')
        id = putJob(games, tc, fcp, scp)
        if id?
            msg = "Job ##{id} added"
            res.send(msg)
            console.log(msg)
        else
            res.send(403)
        return

    app.get '/engine/new', (req, res) ->
        name = req.param('name')
        cmd = req.param('cmd')
        proto = req.param('proto')
        engines[cmd] =
            'name': name
            'cmd': cmd
            'proto': proto
        msg = "Engine '#{name}' added"
        res.send(msg)
        console.log(msg)
        return

    # FIXME Not used
    app.post '/engine/new', (req, res) ->
        engine = req.body.engine
        engines[engine.cmd] =
            'name': engine.name
            'cmd': engine.cmd
            'proto': engine.proto
        executable = engine.executable
        return

    app.listen(3838)

    return
