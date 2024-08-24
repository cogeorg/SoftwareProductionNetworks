#!/usr/local/bin/python3
# -*- coding: utf-8 -*-

__author__="""Co-Pierre Georg (co-pierre.georg@uct.ac.za)"""

import sys
import datetime
import random

import networkx as nx
from tqdm import tqdm

# ###########################################################################
# METHODS
# ###########################################################################

# -------------------------------------------------------------------------
# do_run(file_name)
# -------------------------------------------------------------------------
def do_run(base_directory, identifier):
    input_filename = base_directory + identifier + ".gexf"
 
    print("<<<<<< WORKING ON: " + input_filename)
    
    G = nx.read_gexf(input_filename)  # this is an undirected graph
    
    # nodes, edges
    num_nodes = G.number_of_nodes()
    num_edges = G.number_of_edges()
    print(str(datetime.datetime.now()) + "    << # NODES: " + str(num_nodes) + " # EDGES: " + str(num_edges))

    #
    # check if downstream dependencies B-->C induce a dependency A-->C if A-->B is a dependency
    #
    if True:
        _is = 0
        _not = 0
        _count = 0
        for node in tqdm(G.nodes()):
            for successor in G.successors(node):
                for successor2 in G.successors(successor):
                    if successor2 in G.successors(node):
                        _is += 1
                    else:
                        _not += 1
            _count +=1 
            if _count%100 == 0:
                print(_is, _not)
        print("  << NEIGHBORS OF NEIGHBORS:", _is, " NOT:", _not)

    print(">>>>>> FINISHED")
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
    identifier = args[2]
    
#
# CODE
#
    do_run(base_directory, identifier)
