#!/usr/bin/env coffee

client = require('../lib/client')
program = require('commander')

program
    .version('0.0.1')
    .option('--host <host>', 'connect to <host>', 'localhost')
    .option('--port <port>', 'connect to <port>', Number, 3838)

program
    .command('add-job')
    .description('add a job to the cluster')
    .option('--fcp <cmd>', 'first engine <cmd>')
    .option('--scp <cmd>', 'second engine <cmd>')
    .option('--games <n>', 'play <n> games', Number, 1000)
    #.option('-c, --concurrency <n>', 'divide the task in <n> jobs', Number, 1)
    .option('-n, --number <n>', 'perform the job <n> times', Number, 1)
    .option('-m, --moves <n>', 'play <n> moves in specified time', Number, 40)
    .option('-t, --time <n>', 'play moves in <n> seconds', Number, 10)
    .option('-i, --increment <n>', 'add <n> seconds for each move', Number, 1)
    .action (options) ->
        console.error("  Option '--fcp <cmd>' is missing") unless options.fcp?
        console.error("  Option '--scp <cmd>' is missing") unless options.scp?
        unless options.fcp? and options.scp?
            console.log(options.helpInformation())
            process.exit(1)
        job =
            'fcp': options.fcp 
            'scp': options.scp
            'games': options.games
            'tc': "#{options.moves}/#{options.time}+#{options.increment}"
        client.init(options.parent.host, options.parent.port)
        client.addJobs(job, options.number)
        return

program
    .command('add-engine')
    .description('add an engine to the cluster')
    .option('--name <name>', 'set engine name to <name>')
    .option('--cmd <cmd>', 'set engine command to <cmd>')
    .option('--proto <proto>', 'set engine name to <name>', 'xboard')
    .action (options) ->
        console.error("  Option '--name <name>' is missing") unless options.name?
        console.error("  Option '--cmd <cmd>' is missing") unless options.cmd?
        unless options.name? and options.cmd?
            console.log(options.helpInformation())
            process.exit(1)
        engine =
            'name': options.name
            'cmd': options.cmd
            'proto': options.proto
        client.init(options.parent.host, options.parent.port)
        client.addEngine(engine)
        return

program
    .command('flush-jobs')
    .description('flush jobs on waiting pool')
    .action (options) ->
        client.init(options.parent.host, options.parent.port)
        client.flushJobs()
        return

program.parse(process.argv)

console.log(program.helpInformation()) unless program.args.length > 0
