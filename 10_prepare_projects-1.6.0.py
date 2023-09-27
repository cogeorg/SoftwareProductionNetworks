#!/usr/local/bin/python3
# -*- coding: utf-8 -*-

__author__="""Co-Pierre Georg (co-pierre.georg@uct.ac.za)"""

import sys
import os
import codecs
import datetime

# ###########################################################################
# METHODS
# ###########################################################################

# ensure that each line has the correct number of columns
def preprocess(row):
    columns = row.strip().split(',')

    cleaned_columns = []
    field = ''

    in_field = False
    for column in columns:
        if column == '""':
            cleaned_columns.append('')
        else:
            if '"' in column:
                if in_field:  # closing
                    in_field = False
                    field += column.strip('"').replace(";", " ")
                    cleaned_columns.append(field)
                else:  # opening
                    in_field = True
                    field += column.strip('"').replace(";", " ") + " "
            else:
                if in_field:  # middle
                    field += column.strip('"').replace(";", " ") + " "
                else:  # x1, x3
                    cleaned_columns.append(column.replace(";", " "))
    
    if False:
        print(len(cleaned_columns), cleaned_columns)

    return cleaned_columns


# -------------------------------------------------------------------------
# do_run(file_name)
# -------------------------------------------------------------------------
def do_run(base_directory, input_file_name, output_file_name, manager):

    out_text = "ID;ProjectName;Homepage;RepoURL;RepoID\n"
    out_file = open(base_directory + output_file_name, 'w')
    out_file.write(out_text)
    out_file.close() # ensure file is empty
    out_file = open(base_directory + output_file_name, 'a')

    print("<<<<<< WORKING ON: " + base_directory + input_file_name)
    _count = 0
    _found = 0
    _error = 0

    with open(base_directory + input_file_name, encoding="utf-8", errors='replace') as infile:
        for line in infile:
            _count += 1
            if _count % 1000000 == 0:
                print("    << " + str(datetime.datetime.now()) + "  " + str(_count))
            tokens = preprocess(line.strip())
            # if len(tokens) != 21:
            #     print(len(tokens), line)
            try:
                if tokens[1] == manager or tokens[1] == manager.upper() or tokens[1] == manager.lower():
                    try:
                        out_file.write(tokens[0] + ";" + tokens[2] + ";" + tokens[7] + ";" + tokens[9] + ";" + tokens[20] + "\n")
                        _found += 1
                    except UnicodeEncodeError:  # very rare, but possible
                        print("      << UNICODE ERROR LINE: " + str(_count))
                        _error += 1
            except IndexError:
                _error += 1
                if False:
                    print("  << ERROR: " + line.strip())
    # add output
    out_text += "\n"
    out_file.write(out_text)
    out_file.close()
    print("    >>> FOUND: " + str(_found) + " OF TOTAL: " + str(_count) + " ENTRIES WITH: " + str(_error) + " ERRORS.")
    print("    >>> FILE WRITTEN TO:" + base_directory + output_file_name)
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
    input_file_name = args[2]
    output_file_name = args[3]
    manager = args[4]

#
# CODE
#
    do_run(base_directory, input_file_name, output_file_name, manager)
