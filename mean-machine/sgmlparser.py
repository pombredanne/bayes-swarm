#!/usr/bin/python

from sgmllib import SGMLParser

class BaseHTMLParser(SGMLParser):
    def reset(self):
        self.text = ''
        SGMLParser.reset(self)

    def handle_data(self, data):
        if data:
            self.text = self.text + data

if __name__ == "__main__":
    file = open("/home/matteo/Development/pulsar_test/2/2008/8/15/0cf5123c96ca6f3f6f6050a4348a9f71/contents.html")
    htmldoc = BaseHTMLParser()
    htmldoc.feed(file.read())
    file.close()
    htmldoc.close()
     
    #print htmldoc.title
    print htmldoc.text
