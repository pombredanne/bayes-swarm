#!/usr/bin/python
# -*- coding: UTF-8 -*-

# Licensed under the Apache2 License.

__copyright__ = 'BayesFor Association'
__author__    = 'Matteo Zandi <matteo.zandi@bayesfor.eu>'

stopwords = {'it': ["ad", "al", "allo", "ai", "agli", "all", "agl", "alla", "alle", "con", "col", "coi", "da", "dal", "dallo", "dai", "dagli", "dall", "dagl", "dalla", "dalle", "di", "del", "dello", "dei", "degli", "dell", "degl", "della", "delle", "in", "nel", "nello", "nei", "negli", "nell", "negl", "nella", "nelle", "su", "sul", "sullo", "sui", "sugli", "sull", "sugl", "sulla", "sulle", "per", "tra", "contro", "io", "tu", "lui", "lei", "noi", "voi", "loro", "mio", "mia", "miei", "mie", "tuo", "tua", "tuoi", "tue", "suo", "sua", "suoi", "sue", "nostro", "nostra", "nostri", "nostre", "vostro", "vostra", "vostri", "vostre", "mi", "ti", "ci", "vi", "lo", "la", "li", "le", "gli", "ne", "il", "un", "uno", "una", "ma", "ed", "se", "perch\303\251", "anche", "come", "dov", "dove", "che", "chi", "cui", "non", "pi\303\271", "quale", "quanto", "quanti", "quanta", "quante", "quello", "quelli", "quella", "quelle", "questo", "questi", "questa", "queste", "si", "tutto", "tutti", "a", "c", "e", "i", "l", "o", "ho", "hai", "ha", "abbiamo", "avete", "hanno", "abbia", "abbiate", "abbiano", "avr\303\262", "avrai", "avr\303\240", "avremo", "avrete", "avranno", "avrei", "avresti", "avrebbe", "avremmo", "avreste", "avrebbero", "avevo", "avevi", "aveva", "avevamo", "avevate", "avevano", "ebbi", "avesti", "ebbe", "avemmo", "aveste", "ebbero", "avessi", "avesse", "avessimo", "avessero", "avendo", "avuto", "avuta", "avuti", "avute", "sono", "sei", "\303\250", "siamo", "siete", "sia", "siate", "siano", "sar\303\262", "sarai", "sar\303\240", "saremo", "sarete", "saranno", "sarei", "saresti", "sarebbe", "saremmo", "sareste", "sarebbero", "ero", "eri", "era", "eravamo", "eravate", "erano", "fui", "fosti", "fu", "fummo", "foste", "furono", "fossi", "fosse", "fossimo", "fossero", "essendo", "faccio", "fai", "facciamo", "fanno", "faccia", "facciate", "facciano", "far\303\262", "farai", "far\303\240", "faremo", "farete", "faranno", "farei", "faresti", "farebbe", "faremmo", "fareste", "farebbero", "facevo", "facevi", "faceva", "facevamo", "facevate", "facevano", "feci", "facesti", "fece", "facemmo", "faceste", "fecero", "facessi", "facesse", "facessimo", "facessero", "facendo", "sto", "stai", "sta", "stiamo", "stanno", "stia", "stiate", "stiano", "star\303\262", "starai", "star\303\240", "staremo", "starete", "staranno", "starei", "staresti", "starebbe", "staremmo", "stareste", "starebbero", "stavo", "stavi", "stava", "stavamo", "stavate", "stavano", "stetti", "stesti", "stette", "stemmo", "steste", "stettero", "stessi", "stesse", "stessimo", "stessero", "stando"], 'en': ["a", "about", "above", "after", "again", "against", "all", "am", "an", "and", "any", "are", "aren't", "as", "at", "be", "because", "been", "before", "being", "below", "between", "both", "but", "by", "cannot", "can't", "could", "couldn't", "did", "didn't", "do", "does", "doesn't", "doing", "don't", "down", "during", "each", "few", "for", "from", "further", "had", "hadn't", "has", "hasn't", "have", "haven't", "having", "he", "he'd", "he'll", "her", "here", "here's", "hers", "herself", "he's", "him", "himself", "his", "how", "how's", "i", "i'd", "if", "i'll", "i'm", "in", "into", "is", "isn't", "it", "its", "it's", "itself", "i've", "let's", "me", "more", "most", "mustn't", "my", "myself", "no", "nor", "not", "of", "off", "on", "once", "only", "or", "other", "ought", "our", "ours", "ourselves", "out", "over", "own", "same", "shan't", "she", "she'd", "she'll", "she's", "should", "shouldn't", "so", "some", "such", "than", "that", "that's", "the", "their", "theirs", "them", "themselves", "then", "there", "there's", "these", "they", "they'd", "they'll", "they're", "they've", "this", "those", "through", "to", "too", "under", "until", "up", "very", "was", "wasn't", "we", "we'd", "we'll", "were", "we're", "weren't", "we've", "what", "what's", "when", "when's", "where", "where's", "which", "while", "who", "whom", "who's", "why", "why's", "with", "won't", "would", "wouldn't", "you", "you'd", "you'll", "your", "you're", "yours", "yourself", "yourselves", "you've", "one", "every", "least", "less", "many", "now", "ever", "never", "say", "says", "said", "also", "get", "go", "goes", "just", "made", "make", "put", "see", "seen", "whether", "like", "well", "back", "even", "still", "way", "take", "since", "another", "however", "two", "three", "four", "five", "first", "second", "new", "old", "high", "long"]}

import os
import xapian
import gtk

import logging
format = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
logging.basicConfig(level=logging.DEBUG, format=format)
logging = logging.getLogger('components.core')

def get_components():
    """Load the list of components."""
    logging.debug('Scanning for components')
    components_dir = os.path.join(os.path.dirname(__file__))
    names = [ os.path.basename(path)[:-3] for path in os.listdir(components_dir)
              if path.endswith(".py") ]

    components = {}

    for name in names:
        try:
            mm_component = __import__("components.%s" % name)
        except ImportError, ie:
            logging.warning('Could not load %s component, a library is missing (%s)' % (name, ie.args[0]))
        else:
            component_module = getattr(mm_component, name)

            for attr in dir(component_module):
                obj = getattr(component_module, attr)
                if hasattr(obj, "is_mm_component"):
                    components[obj.name] = obj

    return components

class MMComponent(object):
    def __init__(self):
        pass

class MMRsetFilter(xapian.ExpandDecider):
    def __init__(self, stopwords, keywords=[], progressbar=None, step=0):
        xapian.ExpandDecider.__init__(self)
        self.stopwords = stopwords
        self.keywords = keywords
        self.progressbar = progressbar
        self.step = step
        
    def __call__(self, term):
        #logging.debug('Filtering terms in ESet')
        if self.keywords == []:
            if term[0].islower() and term not in self.stopwords and '_' not in term:
                if self.progressbar is not None:
                    self.progressbar.set_fraction(self.progressbar.get_fraction() + self.step)
                    while gtk.events_pending():
                        gtk.main_iteration()
                    #print term, self.progressbar.get_fraction()
                return True
        else:
            return term in self.keywords

class MMMatchDeciderAlwaysTrue(xapian.MatchDecider):
    def __init__(self, progressbar=None, step=0):
        xapian.MatchDecider.__init__(self)
        self.progressbar = progressbar
        self.step = step

    def __call__(self, doc):
        #logging.debug('Filtering docs in MSet')
        if self.progressbar is not None: 
            self.progressbar.set_fraction(self.progressbar.get_fraction() + self.step)
            while gtk.events_pending():
                gtk.main_iteration()
        return True
