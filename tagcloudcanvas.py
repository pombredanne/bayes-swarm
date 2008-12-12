import gtk
import goocanvas
from random import randint

class TagCloudCanvasText(goocanvas.Text):
#    def __init__(self):
#        goocanvas.Text.__init__(self)

    def get_width(self):
        #return self.get_property('width')
        return self.get_bounds().x2 - self.get_bounds().x1
        
    def get_height(self):
        return self.get_bounds().y2 - self.get_bounds().y1

class TagCloudCanvas(goocanvas.Canvas):
    def __init__(self):
        # tags is an array like so [['item1', 10], ['item2', 20], ...]
        goocanvas.Canvas.__init__(self)
        self.callback_function = None

    def set_callback_function(self, function):
        self.callback_function = function

    def on_rect_button_press (self, view, target, event):
        if self.callback_function == None:
            print "%s item received button press event, no callback function setted" % target
        else:
            self.callback_function(target.get_property('text'))

    def create_and_add_text_item(self, text, size, x, y):
        item = TagCloudCanvasText(text=text,
                                  x=x, y=y,
                                  anchor=gtk.ANCHOR_SW,
                                  #width=200,
                                  font="Sans %i" % size)
        root = self.get_root_item()

        item.connect("button-press-event", self.on_rect_button_press)
        root.add_child(item, 0)
        return item
    
    def set_tags(self, tags):
        self.set_root_item(goocanvas.Group())
        self.tags = tags

        current_x = 0
        current_y = 50
        current_line_heights = []
        for tag, weight in tags:
            text_item = self.create_and_add_text_item(tag, weight, current_x, current_y)
            
            current_x += text_item.get_width() + 10
            # check if we are going over the size of the canvas
            if current_x > self.get_bounds()[2]:
                current_x = 0
                current_y = current_y + max(current_line_heights) + 10
                current_line_heights = []
                text_item.set_property('x', current_x)
                text_item.set_property('y', current_y)
                current_x += text_item.get_width() + 10
            current_line_heights.append(text_item.get_height())

if __name__ == "__main__":
    class Demo:
        def __init__(self):
            w = gtk.Window()
            w.connect('destroy', gtk.main_quit)
            w.set_size_request(700, 300)
            
            canvas = TagCloudCanvas()
            canvas.set_size_request(w.get_size()[0], w.get_size()[1])
            canvas.set_bounds(0, 0, w.get_size()[0], w.get_size()[1])
            
            a = []
            for i in range(1, 50):
                a.append(["item%i" % i, randint(8,24)])

            canvas.set_tags(a)
            w.add(canvas)

            w.show_all()
            gtk.main()
  
    demo = Demo()
