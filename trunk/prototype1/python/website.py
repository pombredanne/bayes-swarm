#!/usr/bin/python

import web
render = web.template.render('templates/')

urls = (
  '/', 'index',
  '/words', 'words',
  '/int_words', 'int_words',
  '/addword', 'addword',
  '/addword2', 'addword2'
)

class index:
    def GET(self):
        print "<h1>bayes-swarm test</h1>"
        print "<a href='/words'>words</a><br>"
        print "<a href='/addword'>add word</a><br>"
        print "<a href='/int_words'>list interesting words</a><br>"

class words:
    def GET(self):
        # FIXME: join words with int_words so that we have stems too
        stems = web.select('words')
        print render.words(stems, cache=False)

class int_words:
    def GET(self):
        stems = web.select('int_words')
        print render.int_words(stems, cache=False)

class addword:
    def GET(self):
        print render.addword()

class addword2:
    def POST(self):
        i = web.input()
        n = web.insert('int_words', name=i.title)
        web.seeother('/')

if __name__ == "__main__":
    web.config.db_parameters = dict(dbn='mysql', user='testuser', pw='test', db='bayesfortest')
    web.run(urls, globals())
