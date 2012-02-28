#!/usr/bin/env ruby

# Copyright (C) 2012 Vincent Ollivier
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

executable = '/usr/bin/bayeselo'
abort 'Usage: bayeselo-results.rb (<pgnfile>)+' unless ARGV.length > 0
abort "Error: cannot open '#{executable}'" unless File.exists? executable
IO.popen(executable, 'r+') do |bayeselo|
    bayeselo.puts 'prompt off'
    ARGV.each { |arg| bayeselo.puts "readpgn #{arg}" }
    bayeselo.puts "elo\nmm\nexactdist\nratings\nx"
    bayeselo.close_write
    is_results = false
    bayeselo.readlines.each do |line|
        next unless is_results or /^Rank/ =~ line
        is_results = true
        puts line
    end
end
