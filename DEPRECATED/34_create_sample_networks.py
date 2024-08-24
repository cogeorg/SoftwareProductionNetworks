#!/usr/local/bin/python3
# -*- coding: utf-8 -*-

__author__="""Co-Pierre Georg (co-pierre.georg@uct.ac.za)"""

import sys
import os
import re
import datetime
import random

import networkx as nx
import numpy as np

# ###########################################################################
# METHODS
# ##########################################################################

# -------------------------------------------------------------------------
# do_run(file_name)
# -------------------------------------------------------------------------
def do_run(base_directory, output_identifier, network_size, param1, param2):
    print(str(datetime.datetime.now()) + " <<<<<< START WORKING ON: " + base_directory + output_identifier)
    print(str(datetime.datetime.now()) + "   << NUM_NODES: " + str(network_size) + " ; PARAM 1: " + str(param1) + " ; PARAM 2: " + str(param2))

    #
    # CREATE THETA DISTRIBUTIONS
    #

    # EQUAL VALUES
    theta_file_name = base_directory + output_identifier + "_theta-equal-" + str(network_size) + ".csv"
    theta_text = "id_sample;theta\n"
    for i in range(0,network_size):
        theta_text += str(i) + ";1.0\n"

    theta_file = open(theta_file_name, "w")
    theta_file.write(theta_text)
    theta_file.close()

    # SKEWED DISTRIBUTION
    theta_file_name = base_directory + output_identifier + "_theta-log_normal-" + str(network_size) + ".csv"
    theta_text = "id_sample;theta\n"
    for i in range(0,network_size):
        rand_val = np.random.lognormal(10.0,2.0)
        theta_text += str(i) + ";" + str(rand_val) + "\n"

    theta_file = open(theta_file_name, "w")
    theta_file.write(theta_text)
    theta_file.close()

    #
    # CREATE NETWORKS
    #

    # STAR -> center outward
    G = nx.DiGraph()
    for i in range(1,network_size):
        G.add_edge(0,i)
    output_file_name = base_directory + output_identifier + "-star_out-" + str(network_size)
    nx.write_gexf(G, output_file_name + ".gexf")
    nx.write_edgelist(G, output_file_name + ".edgelist")

    # STAR -> towards center
    G = nx.DiGraph()
    for i in range(1,network_size):
        G.add_edge(i,0)
    output_file_name = base_directory + output_identifier + "-star_in-" + str(network_size)
    nx.write_gexf(G, output_file_name + ".gexf")
    nx.write_edgelist(G, output_file_name + ".edgelist")

    # COMPLETE
    G = nx.gnp_random_graph(network_size, 1.0, directed=True)
    output_file_name = base_directory + output_identifier + "-complete-" + str(network_size)
    nx.write_gexf(G, output_file_name + ".gexf")
    nx.write_edgelist(G, output_file_name + ".edgelist")

    # ERDOS-RENYI
    # SMALL-WORLD
    # BARABASI-ALBERT

    print(str(datetime.datetime.now()) + " >>>>>> FINISHED")
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
    output_identifier = args[2]
    network_size = int(args[3])
    param1 = float(args[4])
    param2 = float(args[5])

#
# CODE
#
    do_run(base_directory, output_identifier, network_size, param1, param2)
