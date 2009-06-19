# = Bayes :  Sdb Console
# A simple tool to perform SELECT queries against Amazon SDB.
#
# Make sure swarm_shoal_options.yml contains the credentials to connect to
# SDB and just lunch from the command line. You'll get a shell that you can
# use to send queries to SDB, one per line.
# 
# Results are formatted and color coded (you should use a dark background).
# The readline library is used to provide history support and other nice
# command line features.
#
# Once you're done, just type 'quit' and hit return.
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2009 - bayes-swarm project.
# Licensed under the GNU General Public License v2.

require 'rubygems'
require 'right_aws'
require 'readline'
require 'yaml'

sdb_opts = YAML.load(File.open("swarm_shoal_options.yml"))['sdb']
sdb = RightAws::SdbInterface.new(sdb_opts[:access_key], sdb_opts[:secret_key])

loop do
  line = Readline::readline("\e[32msdb>\e[0m ")
  Readline::HISTORY.push(line)
  if line == 'quit'
    exit
  end
  
  limit = Float::MAX
  limit = $1.to_i if line =~ /limit\s+(\d+)/
  count = 0
  if line.strip != ''
    begin
      next_token = nil
      begin
        res = sdb.select(line, next_token)
        next_token = res[:next_token]
        item_output = ''
        res[:items].each do |item|
          itemkey = item.keys.first
          item_output += "\e[36m#{itemkey}\e[0m:\t"
          itemvalues = item.values.first
          item_output += itemvalues.keys.sort.map do |k|
            v = itemvalues[k].first
            if v =~ /[0-9]{10}/
              "\e[33m#{k}\e[0m:#{v.to_i.to_s.rjust(5)}\t"
            else
              "\e[33m#{k}\e[0m:#{v.rjust(8)}\t"
            end
          end.join(',')
          item_output += "\n"
          
          count += 1
          break if count == limit          
        end
        if item_output != ''
          puts item_output
        end
        puts "\e[35mboxusage: #{res[:box_usage]}\e[0m"
        next_token = nil if count == limit
      end while next_token
    rescue Exception => e
      puts "\e[31m#{e}\e[0m"
    end
  end
end