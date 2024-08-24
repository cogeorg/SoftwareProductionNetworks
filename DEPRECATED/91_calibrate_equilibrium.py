#!/usr/local/bin/python3
# -*- coding: utf-8 -*-

__author__="""Co-Pierre Georg (co-pierre.georg@uct.ac.za)"""

import sys
import datetime
import random

import numpy as np
import networkx as nx


# ###########################################################################
# METHODS
# ###########################################################################

# -------------------------------------------------------------------------
# do_run(file_name)
# -------------------------------------------------------------------------
def do_run(base_directory, covariate_identifier, delta, col_p, col_pobs):
    covariate_filename = base_directory + covariate_identifier + ".csv"
    
    if False:
        print(str(datetime.datetime.now()) + " <<<< WORKING USING:" + covariate_filename)

    # CREATE DATA
    covariate_data = np.genfromtxt(covariate_filename, delimiter=' ', skip_header=1, dtype=float)
    p = covariate_data[:,col_p]
    pobs = covariate_data[:,col_pobs]
    if False:
        print(str(datetime.datetime.now()) + "    P DIMENSIONS:",len(p), " MIN:", min(p), "MAX:", max(p))
        print(str(datetime.datetime.now()) + "    POBS DIMENSIONS:",len(pobs), " MIN:", min(pobs), "MAX:", max(pobs))
    
    dist = np.sqrt(np.sum((p - pobs)**2))
    print(delta, dist)
# -------------------------------------------------------------------------


# -------------------------------------------------------------------------
#
#  MAIN
#
# -------------------------------------------------------------------------
if __name__ == '__main__':
#
# VARIABLES
#
    args = sys.argv
    base_directory = args[1]
    covariate_identifier = args[2]
    delta = float(args[3])
    col_p = int(args[4])
    col_pobs = int(args[5])
    
#
# CODE
#
    do_run(base_directory, covariate_identifier, delta, col_p, col_pobs)
