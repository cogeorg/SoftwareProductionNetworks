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
    
    G = nx.read_edgelist(edge_filename, create_using=nx.DiGraph())
    # print(nx.adjacency_spectrum(G))

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

    if False:
        print(Gm, theta)

    #
    # EQUILIBRIUM CASE
    #
    # COMPUTE EQUILIBRIUM
    q_eq = One - theta
    p_eq = inv_mat @ (One - theta)
    print(str(datetime.datetime.now()) + " << FINISHED EQUILIBRIUM COMPUTATION")

    # COMPUTE WELFARE
    W_eq = theta @ (One - p_eq) + 0.5*(One - q_eq) @ (One - q_eq)
    print(str(datetime.datetime.now()) + "   W_eq =", W_eq)

    #
    # SOCIAL OPTIMUM CASE 
    #
    # COMPUTE SOCIAL OPTIMUM
    q_so = One - (inv_mat @ theta)
    p_so = inv_mat @ (One - np.linalg.inv(I - delta*np.transpose(Gm)) @ theta )
    print(str(datetime.datetime.now()) + " << FINISHED SOCIAL OPTIMUM COMPUTATION")

    # COMPUTE WELFARE
    W_so = theta @ (One - p_so) + 0.5*(One - q_so) @ (One - q_so)
    print(str(datetime.datetime.now()) + "   W_so =", W_so)

    #
    # WRITE OUT TEXT
    #
    out_file = open(output_filename, "w")
    out_text = ""
    text_lines = [f"{qeq_i} {peq_i} {qso_i} {pso_i}" for qeq_i, peq_i, qso_i, pso_i in zip(q_eq, p_eq, q_so, p_so)]
    out_text = "\n".join(text_lines)

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
