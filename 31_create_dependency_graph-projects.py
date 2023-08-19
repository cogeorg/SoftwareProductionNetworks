#!/usr/local/bin/python3
# -*- coding: utf-8 -*-

__author__="""Co-Pierre Georg (co-pierre.georg@uct.ac.za)"""

import sys
import os
import re
import datetime
import random

import networkx as nx

# ###########################################################################
# METHODS
# ###########################################################################


# -------------------------------------------------------------------------
# read_version_file(file_name)
# -------------------------------------------------------------------------
def read_version_file(file_name):
    versions = {}

    with open(file_name) as version_file:
        for line in version_file:
            tokens = line.strip().split(";")
            if len(tokens) == 3:  # avoid empty lines
                if "Project ID" not in line:  # drop header
                    try:
                        versions[int(float(tokens[0]))].append(tokens[1])
                    except:
                        versions[int(float(tokens[0]))] = [tokens[1]]

    if False:
        for key in versions:
            print(key, versions[key])

    return versions


# -------------------------------------------------------------------------
# tokenize(v1)
# -------------------------------------------------------------------------
def tokenize(v1):
    _tokens = []
    tokens = v1.split(".")

    for token in tokens:
        # TODO: find all variants of beta, beta1 etc using regexp
        token = re.sub(r"alpha", "", token)
        token = re.sub(r"alpha1", "", token)
        token = re.sub(r"alpha2", "", token)
        token = re.sub(r"alpha3", "", token)
        token = re.sub(r"alpha4", "", token)
        token = re.sub(r"alpha5", "", token)
        token = re.sub(r"alpha6", "", token)
        token = re.sub(r"alpha7", "", token)
        token = re.sub(r"alpha8", "", token)
        token = re.sub(r"alpha9", "", token)
        token = re.sub(r"beta", "", token)
        token = re.sub(r"beta1", "", token)
        token = re.sub(r"beta2", "", token)
        token = re.sub(r"beta3", "", token)
        token = re.sub(r"beta4", "", token)
        token = re.sub(r"beta5", "", token)
        token = re.sub(r"beta6", "", token)
        token = re.sub(r"beta7", "", token)
        token = re.sub(r"beta8", "", token)
        token = re.sub(r"beta9", "", token)
        token = re.sub(r"rc", "", token)
        token = re.sub(r"rc1", "", token)
        token = re.sub(r"rc2", "", token)
        token = re.sub(r"rc3", "", token)
        token = re.sub(r"rc4", "", token)
        token = re.sub(r"rc5", "", token)
        token = re.sub(r"rc6", "", token)
        token = re.sub(r"rc7", "", token)
        token = re.sub(r"rc8", "", token)
        token = re.sub(r"rc9", "", token)
        token = re.sub(r"-","", token)
        token = re.sub(r"pre","", token)
        token = re.sub(r"v","", token)
        token = re.sub(r"f","", token)
        token = re.sub(r"<3","", token)
        token = re.sub(r"<2","", token)
        # token = re.sub(r"<","", token) # TODO: fix dual conditions later

        try:
            token = int(float(token))
            _tokens.append(token)
        except:
            if False:
                print("   <<< ERROR TOKENIZE: " + token)

    return _tokens


# -------------------------------------------------------------------------
# COMPARISONS
# -------------------------------------------------------------------------
def is_geq(v1,v2):
    is_geq = False

    v1_tokens = tokenize(v1)
    v2_tokens = tokenize(v2)

    if False:
        print(v1_tokens,">=", v2_tokens)

    if v1_tokens[0] > v2_tokens[0]: # MAJOR larger, no further check
        is_geq = True
    if v1_tokens[0] == v2_tokens[0]: # MAJOR equal, check MINOR
        try:
            if v1_tokens[1] > v2_tokens[1]: # MINOR larger, no further check
                is_geq = True
        except IndexError:
            pass
        try:
            if v1_tokens[1] == v2_tokens[1]:  # MINOR equal, check PATCH
                try:
                    if v1_tokens[2] >= v2_tokens[2]:  # PATCH larger or equal, all done
                        is_geq = True
                except IndexError:
                    if False:
                        print(v1, v2)
        except IndexError:
            pass

    return is_geq
# -------------------------------------------------------------------------
# def is_leq(v1,v2):
#     is_leq = False
#
#     v1_tokens = tokenize(v1)
#     v2_tokens = tokenize(v2)
#
#     print(v1_tokens,"<=", v2_tokens)
#
#     return is_leq


# -------------------------------------------------------------------------
# compare_versions(v1, v2, comparisons)
# -------------------------------------------------------------------------
def compare_versions(v1, versions, comp):
    ret = []  # return all matches: v1 COMP versions

    # cleaning v1
    v1 = re.sub(r"\s+", "", v1)  # remove whitespaces

    if comp == "geq":  # executed 500 times (~1% of cases)
        tokens = v1.split(">=")
        if len(tokens) == 2:  # the norm, very few entries will have two >= conditions (which also makes no sense)
            if tokens[0] == "":  # select all versions larger than tokens[1]
                v1 = re.sub(r">=", "", v1)  # select everything larger than v1
                for v2 in versions:
                    if is_geq(v1,v2):
                        ret.append(v2)
                    if False:
                        print(v1,v2, is_geq(v1,v2))

    # if comp == "lt":  # executed 5 times or so (~0.01% of cases)
    #     tokens = v1.split("<")
    #     if len(tokens) == 2:  # the norm, very few entries will have two >= conditions (which also makes no sense)
    #         if tokens[0] == "":  # select all versions larger than tokens[1]
    #             v1 = re.sub(r"<", "", v1)  # select everything larger than v1
    #             for v2 in versions:
    #                 if is_leq(v1,v2):
    #                 # print(tokens, is_geq(v1,v2))
    #                     pass
    return ret

# -------------------------------------------------------------------------
# do_run(file_name)
# -------------------------------------------------------------------------
def do_run(base_directory, input_file_name, output_identifier, sample_size):
    line_count = 0
    error_count = 0

    G = nx.DiGraph()
    H = nx.DiGraph()

    print(str(datetime.datetime.now()) + " <<<<<< START WORKING ON: " + base_directory + input_file_name + " AND SAMPLE SIZE: " + str(sample_size))

    with open(base_directory + input_file_name) as infile:
        for line in infile:
            line_count += 1
            tokens = line.strip().split(";")

            if len(tokens) == 2:
                try:
                    from_id = int(tokens[0])
                    to_id = int(tokens[1])
                    G.add_edge(from_id, to_id)
                    if sample_size != 0.0:
                        if random.random() < sample_size:
                            H.add_edge(from_id, to_id)
                except ValueError:  # first row
                    pass

    if True:  # debugging
        print("    << " + str(datetime.datetime.now()) + " G: # Nodes: " + str(len(G.nodes())) + " # Edges: " + str(len(G.edges())))
        if sample_size != 0.0:
            print("    << " + str(datetime.datetime.now()) + " H: # Nodes: " + str(len(H.nodes())) + " # Edges: " + str(len(H.edges())))

    if sample_size != 0.0:
        nx.write_edgelist(H, base_directory + "sampled-" + str(sample_size) + "_" + output_identifier + ".dat", data=False)
        # nx.write_gexf(H, base_directory + "sampled-" + str(sample_size) + "_" + output_identifier + ".gexf")
        print("    << " + str(datetime.datetime.now()) + " SAMPLE FILE WRITTEN TO:" + base_directory + "sampled-" + str(sample_size) + "_" + output_identifier)
    else:
        nx.write_edgelist(G, base_directory + output_identifier + ".dat", data=False)
        # nx.write_gexf(G, base_directory + output_identifier + ".gexf")
        print("    << " + str(datetime.datetime.now()) + " FILE WRITTEN TO:" + base_directory + output_identifier)

    print(str(datetime.datetime.now()) + " >>>>>> FINISHED WORKING ON " + str(line_count) + " LINES")
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
    input_file_name = args[2]
    output_identifier = args[3]
    sample_size = float(args[4])

#
# CODE
#
    do_run(base_directory, input_file_name, output_identifier, sample_size)
