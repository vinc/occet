#!/usr/bin/env ruby

#echo -e "readpgn games.pgn\nelo\nmm\nexactdist\nratings>bayeselo_result.log\nx\nx\n" | bayeselo

unless ARGV.length > 0
    puts 'Usage: bayeselo-results.rb (<pgnfile>)+'
    exit 1
end

IO.popen('bayeselo', 'r+') do |bayeselo|
    bayeselo.puts "prompt off"
    
    ARGV.each { |arg| bayeselo.puts "readpgn #{arg}" }

    bayeselo.puts "elo"
    bayeselo.puts "mm"
    bayeselo.puts "exactdist"
    bayeselo.puts "ratings"
    bayeselo.puts "x"
    
    bayeselo.close_write
    is_results = false
    bayeselo.readlines.each do |line|
        next unless is_results or /^Rank/ =~ line
        is_results = true
        puts line
    end
end
