#!/usr/bin/env python

# gtk.Notebook class with close button on tabs
#
# based on http://coding.debuntu.org/python-gtk-how-customize-size-button-notebook-tab-label

import gtk

class NotebookWithCloseButtonOnTabs(gtk.Notebook):
  def __init__(self):
    gtk.Notebook.__init__(self)

  def append_page(self, child, tab_label, icon=None):
    full_tab_label = self.create_full_tab_label(child, tab_label, icon)
    full_tab_label.show_all()
    
    gtk.Notebook.append_page(self, child, full_tab_label)

  def prepend_page(self, child, tab_label, icon=None):
    full_tab_label = self.create_full_tab_label(child, tab_label, icon)
    full_tab_label.show_all()
    
    gtk.Notebook.prepend_page(self, child, full_tab_label)

  def insert_page(child, tab_label, position, icon=None):
    full_tab_label = self.create_full_tab_label(child, tab_label, icon)
    full_tab_label.show_all()
    
    gtk.Notebook.insert_page(self, child, full_tab_label, position)

  def create_full_tab_label(self, child, tab_label, icon=None):
    # returns a new widget which is the tab_label with a close button
    # and eventually an icon
    box = gtk.HBox()

    # the close button is made of an empty button where we set an image
    closebtn = gtk.Button()
    image = gtk.Image()
    image.set_from_stock(gtk.STOCK_CLOSE, gtk.ICON_SIZE_MENU)
    closebtn.connect("clicked", self.close_tab, child)
    closebtn.set_image(image)
    closebtn.set_relief(gtk.RELIEF_NONE)
    
    if icon is not None:
      box.pack_start(icon, False, False)
    box.pack_start(tab_label, True, True)
    box.pack_end(closebtn, False, False)
    return box

  def close_tab(self, widget, child):
    pagenum = self.page_num(child)
    
    if pagenum != -1:
      self.remove_page(pagenum)
      child.destroy()
    
class Demo():
  def __init__(self):
    window = gtk.Window()
    window.set_title("Custom Gtk.Notebook Tabs example")
    window.resize(600,400)

    box = gtk.VBox()
    button = gtk.Button("New Tab")
    box.pack_start(button,False)
    button.connect("clicked", self.new_tab)

    self.notebook = NotebookWithCloseButtonOnTabs()
    self.notebook.set_scrollable(True)
    self.notebook.set_property('homogeneous', True)    
    box.pack_start(self.notebook, False, False, 0)

    window.add(box)
    window.connect("destroy", gtk.main_quit)
    window.connect("delete-event", gtk.main_quit)
    window.show_all()
    gtk.main()

  def new_tab(self, widget):
    icons = [gtk.STOCK_ABOUT, gtk.STOCK_ADD, gtk.STOCK_APPLY, gtk.STOCK_BOLD] 
    nbpages = self.notebook.get_n_pages()
    icon = icons[nbpages%len(icons)]

    tab_label = gtk.Label(icon)
    tab_label.show()
    child = gtk.Label(icon)
    child.show()
    image = gtk.Image()
    image.set_from_stock(icon, gtk.ICON_SIZE_MENU)
    image.show()
    
    self.notebook.append_page(child, tab_label, image)
    self.notebook.set_current_page(nbpages)

if __name__ == '__main__':
  demo = Demo()
