#!/bin/bash
GITDIR=~/Git/SoftwareProductionNetworks/
BASENAME=Cargo
BASEDIR=~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/
DEPFILE=dependencies_$BASENAME.csv

# ###########################################################################
#
# PRODUCTION RUN
#
# ###########################################################################

#
# STEP 1 -- PREPARE ORIGINAL DATA
#
# FIRST:
# Download raw data from: https://zenodo.org/record/2536573/files/Libraries.io-open-data-1.4.0.tar.gz
# THEN:
# ./10_prepare_dependencies.py \
#   $BASEDIR \
#   libraries-1.4.0-2018-12-22/dependencies-1.4.0-2018-12-22.csv \
#   $BASENAME/$DEPFILE \
#   $BASENAME

# ./11_prepare_projects.py \
#   $BASEDIR/ \
#   libraries-1.4.0-2018-12-22/projects-1.4.0-2018-12-22.csv \
#   $BASENAME/projects_$BASENAME.csv \
#   $BASENAME

# ./12_prepare_versions.py \
#   $BASEDIR \
#   libraries-1.4.0-2018-12-22/versions-1.4.0-2018-12-22.csv \
#   $BASENAME/versions_$BASENAME.csv \
#   2011-01-01 \
#   2021-12-31 \
#   $BASENAME 

#
# STEP 2 - CREATE DEPENDENCY GRAPH
#
# execute in data directory...
# cd $BASEDIR/$BASENAME ; split -l 100000 -d -a 5 $DEPFILE  ; mv x* dependencies/ ; cd dependencies ; for i in `ls` ; do mv $i $i.csv ; done ; cd $GITDIR

# ...then execute in this directory:
# NB: In the last x0**** file generated this way was an extra line which had to be manually removed for the next command to work. Will fix at some point.
# ./20_merge_data.py \
#   $BASEDIR/ \
#   $BASENAME/dependencies/ \
#   $BASENAME/ \
#   $BASENAME

# cd $BASEDIR/$BASENAME ; \
#     rm dependencies_$BASENAME-merged.csv 2>/dev/null ; \
#     cat x*.csv | grep -v "Project ID,Pro" >> dependencies_$BASENAME-merged.csv ; \
#     rm x*.csv
# cd $GITDIR


#
# CREATE DEPENDENCY GRAPH
#

# Note: for large networks, sampling might be helpful. The last number is the sampling probability.
# ./30_create_dependency_graph.py $BASEDIR dependencies_npm-merged.csv dependencies_npm-merged versions_npm-restricted.csv 0.01 
# ./32_create_largest_component.py $BASEDIR enc_sampled-0.01_dependencies_npm-merged

# Note: 0.0 means no cuts applied
# ./30_create_dependency_graph.py $BASEDIR/$BASENAME/ dependencies_$BASENAME-merged.csv dependencies_$BASENAME-merged versions_$BASENAME.csv 0.0
# ./32_create_largest_component.py $BASEDIR/$BASENAME/ dependencies_$BASENAME-merged


#
# ANALYZE GRAPH USING NETWORKX 
#

# ./80_analyze_graph.py \
#   $BASEDIR/$BASENAME/ \
#   dependencies_$BASENAME-merged

#
# PREPARE COVARIATES
#
# Note: Cargo_project_metadata.csv was created using a scraper of the libraries.io website.
#
./50_prepare_covariates.py $BASEDIR/Cargo/covariates/ Cargo_project_metadata.csv covariates_maintainers-1.csv
#./51_prepare_covariates-contributors.py $BASEDIR/Cargo/covariates/ Contributor_commits.csv covariates-contributors-1.csv
