#!/usr/bin/env python
# -*- coding: UTF-8 -*-

# Licensed under the GNU General Public License v2.

"""Mean Machine

Without arguments, immediately loads the mean machine window.
"""

__copyright__ = 'BayesFor Association'
__author__    = 'Matteo Zandi <matteo.zandi@bayesfor.eu>'

from ui.mainwindow import MainMachine

import logging
format = "%(asctime)s %(levelname)s %(name)s: %(message)s"
logging.basicConfig(filename = 'mean-machine.log',
    level = logging.DEBUG, 
    format = format)

logging.info("*** Starting Mean-Machine ***")

mm = MainMachine()

logging.info("*** Quitting Mean-Machine ***")
