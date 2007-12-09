#!/usr/bin/python

import os
# needed by matplotlib
os.environ[ 'HOME' ] = '/tmp'

from pylab import date2num
from websiteplots import plottimeseries, plotmultiscatter

# you need webpy 0.21 or later (included since Ubuntu 7.10 Gutsy)
import web
# comment on production enviroment
# web.webapi.internalerror = web.debugerror
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
  '/words_avg_count', 'words_avg_count',
  '/hits_per_word', 'hits_per_word',
  '/own_query', 'own_query',
  '/plots=(.*)', 'plots',
  '/call_plottimeseries=(.*)', 'call_plottimeseries',
  '/call_plotmultiscatter=(.*)', 'call_plotmultiscatter'
)

class index:
    def GET(self):
        data = {'n_int_words': web.query('SELECT count(*) AS n_int_words FROM int_words;')[0]['n_int_words'],
                'n_words': web.query('SELECT count(*) AS n_words FROM words;')[0]['n_words']}
        print render.base( render.homepage( data ) )

class words:
    def GET(self):
        join_words_intwords = """SELECT a.id, b.name, page_id, scantime, count, titlecount, weight
                                 FROM words a, int_words b
                                 WHERE a.id=b.id"""
        stems = web.query(join_words_intwords)
        print render.base( render.words(stems) )

class pages:
    def GET(self):
        pages = web.select('pages')
        print render.base( '<h2>list of pages</h2>' + render.selectall(pages) )

class sources:
    def GET(self):
        sources = web.select('sources')
        print render.base( '<h2>list of sources</h2>' + render.selectall(sources) )

class int_words:
    def GET(self):
        stems = web.select('int_words')
        print render.base( render.int_words(stems) )

class addword:
    def __init__(self):
        current_words_query = '''SELECT name FROM int_words'''
        self.myform = form.Form(
            form.Textbox('word',
                form.notnull,
                form.Validator("Can't be blank", lambda x:x.strip() is not ""),
                form.Validator("Already in table",
                    lambda x: len(web.query("SELECT name FROM int_words WHERE name='%s'" % x)) == 0)
                ),
            form.Hidden('hidden', **{'submitted': False}))

    def GET(self):
        print render.base( render.addword(self.myform()) )

    def POST(self):
        form = self.myform()
        if not form.validates():
            print render.base( render.addword(form) )
        else:
            form['hidden'].attrs['submitted'] = True
            word = form['word'].value
            web.insert('int_words', name=word)
            print render.base( render.addword(form) )

#
# Queries
#

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
        print render.base( '<h2>most 5 popular words with page and date</h2>' + render.selectall(res) )

class words_avg_count:
    def GET(self):
        words_avg_count_query = '''SELECT a.id, c.name, avg(a.count)
                                   FROM words a, int_words c
                                   WHERE a.id=c.id group by a.id, c.name
                                   ORDER BY avg(a.count) desc;'''
        res = web.query(words_avg_count_query)
        print render.base( '<h2>Average count per word per day</h2>' + render.selectall(res) )

class hits_per_word:
    def GET(self):
        hits_per_word_query = '''select id, name, count(*)
                                 from (

                                  SELECT a.id, c.name, date(a.scantime)
                                 FROM words a, pages b, int_words c
                                 WHERE a.page_id=b.id and a.id = c.id
                                 group by a.id,c.name, date(a.scantime)

                                 ) as a
                                 group by id,name
                                 order by count(*) desc;'''
        res = web.query(hits_per_word_query)
        print render.base( '<h2>Number of hits per word</h2>' + render.selectall(res) )

class own_query:
    def GET(self):
        print render.base( render.own_query() )

    def POST(self):
        i = web.input()
        res = web.query(i.postarea)
        print render.base( '<h2>own query</h2>' + i.postarea + '<br><i>returned</i>' + render.selectall(res) )

#
# Plots
#

class plots:
    def __init__(self):
        # find stems to be included in the dropdown list
        results = web.query('''SELECT DISTINCT id, name as stem
                               FROM int_words
                               WHERE id in (SELECT id from words);''')
        selectable_stems = []
        for result in results:
            selectable_stems.append( ( result.id, result.stem) )

        # find pages to be included in the dropdown list
        results = web.query('''SELECT DISTINCT id, url
                               FROM pages
                               WHERE id in (SELECT page_id as id FROM words);''')

        selectable_pages = []
        for result in results:
            selectable_pages.append( ( result.id, result.url) )

        # requires webpy 0.21, since that version form.Dropdown accepts
        # tuples as arguments
        self.myform = form.Form(
          form.Dropdown('stems',
            selectable_stems,
            form.Validator('select at least one stem', lambda x:len(x)>0),
            **{'multiple': None, 'size': 10}),
          form.Dropdown('pages',
            selectable_pages,
            form.Validator('select at least one page', lambda x:len(x)>0),
            **{'multiple': None, 'size': 10}))

        self.plots = {'plottimeseries': "Time series plot",
          'plotmultiscatter': "Multi scatter plot"}

    def GET(self, plot):
        if plot in self.plots.keys():
            form = self.myform()
            print render.base( render.plots(form) )
        else:
            print render.base( "<h2>Wrong plot name</h2><p>You have selected a wrong plot</p>" )

    def POST(self, plot):
        form = self.myform()
        if not form.validates(web.input(stems=[], pages=[])):
            print render.base( render.plots(form) )
        else:
            # selected_ids is a list of ids, while form returns strings
            selected_ids_strings = form['stems'].value
            selected_ids = []
            for id in selected_ids_strings: selected_ids.append(int(id))

            selected_pages_strings = form['pages'].value
            selected_pages = []
            for id in selected_pages_strings: selected_pages.append(int(id))

            # pass data like a cgi: "/ids=[]&pages=[]"
            html = '<h2>%s</h2><img src="call_%s=%s">' % (
              self.plots[plot], plot,
              "ids=%s&pages=%s" % ( str(selected_ids), str(selected_pages) ) )
            print render.base ( html )

class call_plottimeseries:
    def GET(self, params):
        # for some reason sql returns Decimal(10.0000)
        Decimal = float
        # convert something like "ids=[]&pages=[]" to a dict of params
        params_list = params.split("&")
        params_dict = {}
        for param in params_list:
            arg, value = param.split("=")
            params_dict[arg] = list([int(x) for x in value[1:-1].split(",")])

        # get values for selected stems
        ids_list = (params_dict['ids'] and reduce(lambda x,y: str(x) + ", " + str(y), params_dict['ids'])) or ""
        pages_list = (params_dict['pages'] and reduce(lambda x,y: str(x) + ", " + str(y), params_dict['pages'])) or ""
        query_stems_count = '''SELECT a.id, c.name, avg(a.count) as num, date(a.scantime) as data
                               FROM words a, int_words c, pages b
                               WHERE a.id = c.id
                                 AND a.page_id = b.id
                                 AND a.id IN (%s) AND a.page_id IN (%s)
                               GROUP BY a.id, c.name, date(a.scantime);''' % (ids_list, pages_list)
        results = web.query(query_stems_count)
        results_list = list(results)

        dates_and_values = []
        for id in params_dict['ids']:
            current_id_stuff = filter(lambda x: x.id == id, results_list)
            dates_id = []
            values_id = []
            for i, stuff in enumerate(current_id_stuff):
                # dates are converted to numbers
                dates_id.append(date2num(stuff['data']))
                values_id.append(stuff['num'])
            dates_and_values.append( ( "%d - %s" % (stuff['id'], stuff['name']), dates_id, values_id) )

        image_buffer = plottimeseries(dates_and_values)
        web.header("Content-Type","image/png")
        print image_buffer

class call_plotmultiscatter:
    def GET(self, params):
        # for some reason sql returns Decimal(10.0000)
        Decimal = float
        # convert something like "ids=[]&pages=[]" to a dict of params
        params_list = params.split("&")
        params_dict = {}
        for param in params_list:
            arg, value = param.split("=")
            params_dict[arg] = list([int(x) for x in value[1:-1].split(",")])

        # get values for selected stems
        ids_list = (params_dict['ids'] and reduce(lambda x,y: str(x) + ", " + str(y), params_dict['ids'])) or ""
        pages_list = (params_dict['pages'] and reduce(lambda x,y: str(x) + ", " + str(y), params_dict['pages'])) or ""
        query_stems_count = '''SELECT a.id, c.name, avg(a.count) as num, date(a.scantime) as data
                               FROM words a, int_words c, pages b
                               WHERE a.id = c.id
                                 AND a.page_id = b.id
                                 AND a.id IN (%s) AND a.page_id IN (%s)
                               GROUP BY a.id, c.name, date(a.scantime);''' % (ids_list, pages_list)
        results = web.query(query_stems_count)
        results_list = list(results)

        dates_and_values = []
        for id in params_dict['ids']:
            current_id_stuff = filter(lambda x: x.id == id, results_list)
            dates_id = []
            values_id = []
            for i, stuff in enumerate(current_id_stuff):
                # dates are converted to numbers
                dates_id.append(date2num(stuff['data']))
                values_id.append(float(stuff['num']))
            dates_and_values.append( ( "%d - %s" % (stuff['id'], stuff['name']), dates_id, values_id) )

        image_buffer = plotmultiscatter(dates_and_values)
        web.header("Content-Type","image/png")
        print image_buffer

if __name__ == "__main__":
    web.config.db_parameters = dict(dbn='mysql', user='webuser', pw='test', db='bayesfortest')

    # uncomment if website.py runs as cgi with apache
    web.wsgi.runwsgi = lambda func, addr=None: web.wsgi.runfcgi(func, addr)

    web.run(urls, globals())
