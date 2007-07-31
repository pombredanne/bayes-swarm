#!/usr/bin/python

import web
render = web.template.render('templates/')

urls = (
  '/', 'index',
  '/words', 'words',
  '/pages', 'pages',
  '/sources', 'sources',
  '/int_words', 'int_words',
  '/addword', 'addword',
  '/addword2', 'addword2'
)

class index:
    def GET(self):
        print "<h1>bayes-swarm test</h1>"
        print "<a href='/words'>words</a><br>"
        print "<a href='/pages'>pages</a><br>"
        print "<a href='/sources'>sources</a><br>"
        print "<a href='/int_words'>list interesting words</a> (<a href='/addword'>add word</a>)<br>"

class words:
    def GET(self):
        join_words_intwords = """SELECT a.id, b.name, page_id, scantime, count, titlecount, weight
                                 FROM words a, int_words b 
                                 WHERE a.id=b.id"""
        stems = web.query(join_words_intwords) 
        print render.words(stems, cache=False)

class pages:
    def GET(self):
        pages = web.select('pages')
        print render.selectall(pages)

class sources:
    def GET(self):
        sources = web.select('sources')
        print render.selectall(sources)
            
class int_words:
    def GET(self):
        stems = web.select('int_words')
        print render.int_words(stems, cache=False)

class addword:
    def GET(self):
        print render.addword()

    def POST(self):
        i = web.input()
        n = web.insert('int_words', name=i.title)
        web.seeother('/')

if __name__ == "__main__":
    web.config.db_parameters = dict(dbn='mysql', user='testuser', pw='test', db='bayesfortest')
    web.run(urls, globals())
