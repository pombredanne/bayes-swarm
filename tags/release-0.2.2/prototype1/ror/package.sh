#!/bin/sh
find . | grep "sessions/ruby_sess" > deploy/contents.list
find . | grep ".svn" >> deploy/contents.list
find . | grep "./deploy" >> deploy/contents.list 
find . | grep ".DS_Store" >> deploy/contents.list 
find . | grep "./data-dev" >> deploy/contents.list 
find . | grep "./comment-dev" >> deploy/contents.list 
find . | grep "./bluecurve.png" >> deploy/contents.list 
find . | grep "./log/development.log" >> deploy/contents.list 
find . | grep "./log/production.log" >> deploy/contents.list 
find . | grep "./log/server.log" >> deploy/contents.list 
find . | grep "./log/test.log" >> deploy/contents.list 
tar czvf deploy/swarm_ror_$( date +%Y%m%d ).tar.gz --exclude-from=deploy/contents.list .
