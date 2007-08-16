#!/usr/bin/python
import os
# needed by matplotlib
os.environ[ 'HOME' ] = '/tmp'

from pylab import date2num
from websiteplots import plottimeseries

# you need webpy 0.21 or later (included since Ubuntu 7.10 Gutsy)
import web
render = web.template.render('templates/')

from web import form

urls = (
  '/', 'index',
  '/words', 'words',
  '/pages', 'pages',
  '/sources', 'sources',
  '/int_words', 'int_words',
  '/addword', 'addword',
  '/most_5_words', 'most_5_words',
  '/own_query', 'own_query',
  '/plot_time_series', 'plot_time_series'
)

class index:
    def GET(self):
        web.header("Content-Type","text/html; charset=utf-8")
        print "<html><head><title>wiki pages</title></head><body>"
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
        print "<a href='plot_time_series'>time series plot</a><br>"
        print '<script src="http://www.google-analytics.com/urchin.js" type="text/javascript"></script><script type="text/javascript">_uacct = "UA-2429415-1";urchinTracker();</script>'
        print "</body></html>"

        web.internalerror = web.debugerror        

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

myform = form.Form(form.Dropdown('french',
                   ['mustard', 'fries', 'wine', 'fromage'],
                   form.notnull,
                   **{'multiple': None, 'size': 3}))

class plot_time_series:
    def __init__(self):
        # find stems to included in the dropdown list
        results = web.query('''SELECT DISTINCT a.id, b.name as stem
                           FROM words a, int_words b
                           WHERE a.id=b.id;''')

        selectable_stems = []
        for result in results:
            selectable_stems.append( ( result.id, result.stem) )

        # requires webpy 0.21, since that version form.Dropdown accepts
        # tuples as arguments
        self.myform = form.Form(
          form.Dropdown('stems',
                     selectable_stems,
                     form.Validator('select at least one stem', lambda x:len(x)>0),
                     **{'multiple': None, 'size': 10}))

    def GET(self):
        form = self.myform()
        print render.plot_time_series(form)

    def POST(self):
        form = self.myform()
        if not form.validates(web.input(stems=[])):
            print render.plot_time_series(form)
        else:
            # selected_ids is a list of ids
            selected_string_ids = form['stems'].value
            selected_ids = []
            for id in selected_string_ids: selected_ids.append(int(id))

            # get values for selected stems
            list_ids = (selected_ids and reduce(lambda x,y: str(x) + ", " + str(y), selected_ids)) or ""
            query_stems_count = '''SELECT a.id, c.name, avg(a.count) as num, date(a.scantime) as data
                                   FROM words a, int_words c
                                   WHERE a.id = c.id AND a.id IN (%s)
                                   GROUP BY a.id, c.name, date(a.scantime);''' % (list_ids)
            results = web.query(query_stems_count)
            results_list = list(results)

            dates_and_values = []
            for id in selected_ids:
                current_id_stuff = filter(lambda x: x.id == id, results_list)
                dates_id = []
                values_id = []
                for i, stuff in enumerate(current_id_stuff):
                    # dates are converted to numbers
                    dates_id.append(date2num(stuff['data']))
                    values_id.append(stuff['num'])
                dates_and_values.append( ( str(stuff['id']) + " - " + stuff['name'], dates_id, values_id) )

            # FIXME: header should be part of plottimeseries function
            web.header("Content-Type","image/png")
            image_buffer = plottimeseries(dates_and_values)
            print image_buffer

if __name__ == "__main__":
    web.config.db_parameters = dict(dbn='mysql', user='webuser', pw='test', db='bayesfortest')

    # uncomment if website.py runs as cgi with apache
    web.wsgi.runwsgi = lambda func, addr=None: web.wsgi.runfcgi(func, addr)

    web.run(urls, globals())
