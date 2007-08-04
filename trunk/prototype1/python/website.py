#!/usr/bin/python

import web
render = web.template.render('templates/')
web.internalerror = web.debugerror

urls = (
  '/', 'index',
  '/words', 'words',
  '/pages', 'pages',
  '/sources', 'sources',
  '/int_words', 'int_words',
  '/addword', 'addword',
  '/most_5_words', 'most_5_words',
  '/own_query', 'own_query'
)

class index:
    def GET(self):
        web.header("Content-Type","text/html; charset=utf-8") 
#        print "<html><head><title>wiki pages</title></head><body>"
        print "<h1>bayes-swarm test</h1>"
        print "<h2>tables</h2>"
        print "<a href='words'>words</a><br>"
        print "<a href='pages'>pages</a><br>"
        print "<a href='sources'>sources</a><br>"
        print "<a href='int_words'>list interesting words</a> (<a href='addword'>add word</a>)<br>"

        print "<h2>queries</h2>"
        print "<a href='most_5_words'>most 5 popular words with date and page</a><br>"        
        print "<a href='own_query'>my own query</a><br>"
        
        print "<h2>graphs</h2>"
        print "TODO"
#        print "</body></html>"

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
        web.insert('int_words', name=i.title)
        web.seeother('./')

class most_5_words:
    def GET(self):
        most_5_words_query = '''SELECT a.id, b.name, a.count, a.scantime, c.url
                                FROM   words a, int_words b, pages c
                                WHERE  a.id=b.id 
                                  AND a.page_id=c.id
                                  AND (a.id, a.count) in (SELECT id, MAX(count) FROM words GROUP BY id)
                                ORDER BY a.count DESC
                                LIMIT 5;'''
        res = web.query(most_5_words_query)
        print render.selectall(res)

class own_query:
    def GET(self):
        print render.own_query()

    def POST(self):
        i = web.input()
        res = web.query(i.postarea)
        print render.selectall(res)

if __name__ == "__main__":
    web.config.db_parameters = dict(dbn='mysql', user='testuser', pw='test', db='bayesfortest')
    #web.wsgi.runwsgi = lambda func, addr=None: web.wsgi.runfcgi(func, addr)
    web.run(urls, globals())
