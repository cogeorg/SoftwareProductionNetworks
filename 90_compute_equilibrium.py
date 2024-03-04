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
def do_run(base_directory, dependency_identifier, covariate_identifier, delta, col_num):
    edge_filename = base_directory + dependency_identifier + ".edgelist"
    covariate_filename = base_directory + covariate_identifier + ".csv"

    output_filename = base_directory + "equilibria_" + dependency_identifier + ".csv"

    print(str(datetime.datetime.now()) + " <<<< WORKING")
    print(str(datetime.datetime.now()) + "  DEPENDENCIES: " + edge_filename)
    print(str(datetime.datetime.now()) + "  COVARIATES: " + covariate_filename)
    
    # TO USE THE NETWORK STORED IN THE EDGE_FILENAME, USE THE BELOW:
    G = nx.read_edgelist(edge_filename, create_using=nx.DiGraph())
    
    # OTHERWISE, USE UNTIL >>> TO MANUALLY ADD EDGES TO AN EMPTY GRAPH
    # <<<
    # G = nx.create_empty_copy(
    #     nx.read_edgelist(edge_filename, create_using=nx.DiGraph())                     
    #                          )
    # print(G.nodes())
    # G.add_edges_from([('0','1')])
    # G.add_edges_from([('1','2')])
    # G.add_edges_from([('0','2')])
    # >>>

    # nodes, edges
    num_nodes = G.number_of_nodes()
    num_edges = G.number_of_edges()
    
    print(str(datetime.datetime.now()) + "  DELTA: " + str(delta))
    print(str(datetime.datetime.now()) + "  COL_NUM: " + str(col_num))
    print(str(datetime.datetime.now()) + "  # NODES: " + str(num_nodes) + " # EDGES: " + str(num_edges))

    # CREATE DATA
    covariate_data = np.genfromtxt(covariate_filename, delimiter=';', skip_header=1, dtype=float)
    theta = covariate_data[:,col_num] # normalized in stata
    # theta = (1.0/num_nodes)*np.ones(num_nodes)  # only for debugging purposes
    
    Gm = nx.to_numpy_array(G)
    I = np.eye(num_nodes)
    One = np.ones(num_nodes)
    
    inv_mat = np.linalg.inv(I - delta*Gm)
    print(str(datetime.datetime.now()) + "  COMPUTED inv_mat")
    inv_mat_trans = np.linalg.inv(I - delta*np.transpose(Gm))
    print(str(datetime.datetime.now()) + "  COMPUTED inv_mat_trans")

    if False:
        print("Gm = \n", Gm)
        print("theta = ", theta)
        print("inv_mat = \n", inv_mat)
        print("inv_mat_trans = \n", inv_mat_trans)
    #
    # EQUILIBRIUM CASE
    #
    # COMPUTE EQUILIBRIUM
    # q_eq = One - theta  # checked and correct
    # p_eq = inv_mat @ q_eq  # checked and correct
    q_eq = One / np.sqrt(theta)
    p_eq = inv_mat @ q_eq
    print(str(datetime.datetime.now()) + " << FINISHED EQUILIBRIUM COMPUTATION")

    # COMPUTE TOTAL COST
    TCD_eq = np.sum(np.sqrt(theta))
    print(str(datetime.datetime.now()) + "  TCD_eq =", TCD_eq)
    TCF_eq = np.transpose(theta) @ p_eq
    print(str(datetime.datetime.now()) + "  TCF_eq =", TCF_eq)

    #
    # SOCIAL OPTIMUM CASE 
    #
    # COMPUTE SOCIAL OPTIMUM
    # q_so = One - (np.linalg.inv(I - delta*np.transpose(Gm)) @ theta) # checked and correct
    # p_so = inv_mat @ (One - np.linalg.inv(I - delta*np.transpose(Gm)) @ theta )  # checked and correct
    q_so = 1/np.sqrt(np.transpose(theta) @ inv_mat )
    p_so = inv_mat @ (1.0/np.sqrt( np.transpose(theta) @ inv_mat ))
    print(str(datetime.datetime.now()) + " << FINISHED SOCIAL OPTIMUM COMPUTATION")

    # COMPUTE TOTAL COST
    TCD_so = np.sum( np.sqrt( np.transpose(theta) @ inv_mat ) )
    print(str(datetime.datetime.now()) + "  TCD_so =", TCD_so)
    TCF_so = np.sum( np.sqrt( np.transpose(theta) @ inv_mat ) )
    print(str(datetime.datetime.now()) + "  TCF_so =", TCF_so)

    #
    # WRITE OUT TEXT
    #
    out_file = open(output_filename, "w")
    out_text = "i theta q_eq p_eq q_so p_so\n"

    for i in range(0,num_nodes):
        out_text += str(i) + " " + str(theta[i]) + " " + str(q_eq[i]) + " " + str(p_eq[i]) + " " + str(q_so[i]) + " " + str(p_so[i]) + "\n"
        # out_text += f"{q_eq[i]: .4f} {p_eq[i]: .4f} {q_so[i]: .4f} {p_so[i]: .4f}\n"
    
    # print(out_text)
    out_file.write(out_text)
    out_file.close()
    print("  >> FILE WRITTEN TO:" + output_filename)

    if False:
        print(out_text)
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
    col_num = int(args[5])
    
#
# CODE
#
    do_run(base_directory, dependency_identifier, covariate_identifier, delta, col_num)
