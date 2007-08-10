#!/usr/bin/python

import matplotlib
#matplotlib.use('GD')
matplotlib.use('Agg')
from pylab import date2num
#http://www.dalkescientific.com/writings/diary/archive/2005/04/23/matplotlib_without_gui.html

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
        print "<a href='plot_time_series'>time series plot</a><br>"
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
            selectable_stems.append( (str(result.id), result.stem) )

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
            print "Selected ids: %s <br>" %(selected_ids)

            # get values for selected stems
            list_ids = (selected_ids and reduce(lambda x,y: str(x) + ", " + str(y), selected_ids)) or ""
            query_stems_count = '''SELECT a.id, c.name, avg(a.count) as num, date(a.scantime) as data
                                   FROM words a, int_words c
                                   WHERE a.id = c.id AND a.id IN (%s)
                                   GROUP BY a.id, c.name, date(a.scantime);''' % (list_ids)
            results = web.query(query_stems_count)
            results_list = list(results)
            
            dates = []
            values = []
            for id in selected_ids:
                current_id_stuff = filter(lambda x: x.id == id, results_list)
                dates_id = []
                values_id = []
                for i, stuff in enumerate(current_id_stuff):
                    # FIXME: convert dates from datetime.dates(2007,07,31) to 37000
                    dates_id.append(date2num(stuff['data']))
                    values_id.append(stuff['num'])
                plot(dates_id, values_id, label = str(id))
            
            legend()
            savefig("./static/test_plot")
            web.header("Content-Type","text/html; charset=utf-8")
            print '<img src="./static/test_plot.png">'
                            
            
if __name__ == "__main__":
    web.config.db_parameters = dict(dbn='mysql', user='testuser', pw='test', db='bayesfortest')
    #web.wsgi.runwsgi = lambda func, addr=None: web.wsgi.runfcgi(func, addr)
    web.internalerror = web.debugerror
    web.run(urls, globals())
