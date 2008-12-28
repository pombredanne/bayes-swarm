#!/usr/bin/python
# -*- coding: UTF-8 -*-

# Licensed under the Apache2 License.

"""Mean Machine

Without arguments, immediately loads the mean machine window.
"""

__copyright__ = 'BayesFor Association'
__author__    = 'Matteo Zandi <matteo.zandi@bayesfor.eu>'

import os
from optparse import OptionParser
from ui.mainwindow import MMMainWindow

def get_components():
    """Load the list of components."""
    components_dir = os.path.join(os.path.dirname(__file__), 'components')
    names = [ os.path.basename(path)[:-3] for path in os.listdir(components_dir)
              if path.endswith(".py") ]

    components = {}

    for name in names:
        mm_component = __import__("components.%s" % name)
        component_module = getattr(mm_component, name)

        for attr in dir(component_module):
            obj = getattr(component_module, attr)
            if hasattr(obj, "is_mm_component"):
                components[obj.name] = obj

    return components

components = get_components()
main_window = MMMainWindow(components)
