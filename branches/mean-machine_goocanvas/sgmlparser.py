#!/usr/bin/python

from sgmllib import SGMLParser

class MMBaseHTMLParser(SGMLParser):
    def reset(self):
        # extend (called by SGMLParser.__init__)
        self.text = ''
        self.threshold = 2
        SGMLParser.reset(self)
        
    def handle_data(self, data):
        brackets_count = 0
        for char in data:
            if char == "{": brackets_count += 1
        if data and brackets_count < self.threshold:
          self.text = self.text + data

class BaseHTMLParser(SGMLParser):
    def reset(self):
        self.text = ''
        SGMLParser.reset(self)

    def handle_data(self, data):
        if data:
            self.text = self.text + unicode(data, 'utf8')

if __name__ == "__main__":
    file = open("/home/matteo/Development/pagestore/ioamofi/2008/11/15/73054c23635c2745ec90dffaef5213f0/fb9b11ac9812a44afd9d2abc32a72272/contents.html")
    htmldoc = MMBaseHTMLParser()
    htmldoc.feed(file.read())
    file.close()
    htmldoc.close()
     
    #print htmldoc.title
    print htmldoc.text
