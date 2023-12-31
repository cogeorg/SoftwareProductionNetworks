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
def do_run(base_directory, dependency_identifier, covariate_identifier, delta):
    edge_filename = base_directory + dependency_identifier + ".edgelist"
    covariate_filename = base_directory + covariate_identifier + ".csv"

    output_filename = base_directory + "equilibria_" + dependency_identifier + ".csv"

    print(str(datetime.datetime.now()) + " <<<< WORKING")
    print(str(datetime.datetime.now()) + "  DEPENDENCIES: " + dependency_identifier)
    print(str(datetime.datetime.now()) + "  COVARIATES: " + covariate_identifier)
    
    # TO USE THE NETWORK STORED IN THE EDGE_FILENAME, USE THE BELOW:
    # G = nx.read_edgelist(edge_filename, create_using=nx.DiGraph())

    # OTHERWISE, USE UNTIL >>> TO MANUALLY ADD EDGES TO AN EMPTY GRAPH
    # <<<
    G = nx.create_empty_copy(
        nx.read_edgelist(edge_filename, create_using=nx.DiGraph())                     
                             )
    print(G.nodes())
    G.add_edges_from([('0','1')])
    G.add_edges_from([('1','2')])
    # G.add_edges_from([('0','2')])
    # >>>

    # nodes, edges
    num_nodes = G.number_of_nodes()
    num_edges = G.number_of_edges()
    
    print(str(datetime.datetime.now()) + "  # NODES: " + str(num_nodes) + " # EDGES: " + str(num_edges))

    # CREATE DATA
    covariate_data = np.genfromtxt(covariate_filename, delimiter=';', skip_header=1, dtype=float)
    theta = covariate_data[:,4]/np.sum(covariate_data[:,4])
    Gm = nx.to_numpy_array(G)
    
    I = np.eye(num_nodes)
    One = np.ones(num_nodes)

    inv_mat = np.linalg.inv(I - delta*Gm)

    if True:
        print(Gm, theta)
        print(inv_mat)
    #
    # EQUILIBRIUM CASE
    #
    # COMPUTE EQUILIBRIUM
    q_eq = One - theta  # checked and correct
    p_eq = inv_mat @ (One - theta)  # checked and correct
    print(str(datetime.datetime.now()) + " << FINISHED EQUILIBRIUM COMPUTATION")

    # COMPUTE WELFARE
    W_eq = theta @ (One - p_eq) + 0.5*(One - q_eq) @ (One - q_eq)
    print(str(datetime.datetime.now()) + "   W_eq =", W_eq)

    #
    # SOCIAL OPTIMUM CASE 
    #
    # COMPUTE SOCIAL OPTIMUM
    q_so = One - (inv_mat @ theta) # checked and correct
    p_so = inv_mat @ (One - np.linalg.inv(I - delta*np.transpose(Gm)) @ theta )  # checked and correct
    print(str(datetime.datetime.now()) + " << FINISHED SOCIAL OPTIMUM COMPUTATION")

    # COMPUTE WELFARE
    W_so = theta @ (One - p_so) + 0.5*(One - q_so) @ (One - q_so)
    print(str(datetime.datetime.now()) + "   W_so =", W_so)

    #
    # WRITE OUT TEXT
    #
    out_file = open(output_filename, "w")
    out_text = "i q_eq p_eq q_so p_so\n"

    for i in range(0,num_nodes):
        out_text += str(i) + " " +str(q_eq[i]) + " " + str(p_eq[i]) + " " + str(q_so[i]) + " " + str(p_so[i]) + "\n"
    
    print(out_text)
    out_file.write(out_text)
    out_file.close()
    print("  >> FILE WRITTEN TO:" + output_filename)

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
    dependency_identifier = args[2]
    covariate_identifier = args[3]
    delta = float(args[4])
    
#
# CODE
#
    do_run(base_directory, dependency_identifier, covariate_identifier, delta)
