#!/usr/bin/python
import os
# needed by matplotlib
os.environ[ 'HOME' ] = '/tmp'

from pylab import date2num
from websiteplots import plottimeseries

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
  '/own_query', 'own_query',
  '/plot_time_series', 'plot_time_series',
  '/call_plottimeseries', 'call_plottimeseries'
)

class index:
    def GET(self):
        print render.base("")

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

class own_query:
    def GET(self):
        print render.base( render.own_query() )

    def POST(self):
        i = web.input()
        res = web.query(i.postarea)
        print render.base( '<h2>own query</h2>' + i.postarea + '<br><i>returned</i>' + render.selectall(res) )

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
        print render.base( render.plot_time_series(form) )

    def POST(self):
        form = self.myform()
        if not form.validates(web.input(stems=[])):
            print render.base( render.plot_time_series(form) )
        else:
            # selected_ids is a list of ids
            selected_string_ids = form['stems'].value
            selected_ids = []
            for id in selected_string_ids: selected_ids.append(int(id))

            # we use cookies to pass data
            web.setcookie('selected_ids', selected_ids)
            html = '<h2> Time series plot</h2><img src="call_plottimeseries">'
            print render.base ( html )

class call_plottimeseries:
    def GET(self):
        session = web.cookies()

        # for some reason sql returns Decimal(10.0000)
        Decimal = float
        # cookies return strings like "[1,2,3]", let's convert them to lists
        selected_ids_cookies = session['selected_ids']
        selected_ids = list([int(x) for x in selected_ids_cookies[1:-1].split(",")])

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
            dates_and_values.append( ( "%d - %s" % (stuff['id'], stuff['name']), dates_id, values_id) )

        image_buffer = plottimeseries(dates_and_values)
        web.header("Content-Type","image/png")
        print image_buffer

if __name__ == "__main__":
    web.config.db_parameters = dict(dbn='mysql', user='webuser', pw='test', db='bayesfortest')

    # uncomment if website.py runs as cgi with apache
    web.wsgi.runwsgi = lambda func, addr=None: web.wsgi.runfcgi(func, addr)

    web.run(urls, globals())
