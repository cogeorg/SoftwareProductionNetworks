#!/usr/bin/env bash
BASEDIR=~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/
GITDIR=~/Git/SoftwareProductionNetworks/

# ###########################################################################
#
# PRODUCTION RUN 1.6.0 -- Cargo
#
# ###########################################################################
VERSION=1.6.0-2020-01-12
BASENAME=Cargo-1.6.0
LANGUAGE=Rust
DEPFILE=dependencies_$BASENAME.csv

#
# STEP 0 -- COPY ORIGINAL DATA
#
# mkdir $BASEDIR/$BASENAME/ 2>/dev/null
# cp -R ~/Dropbox/Papers/10_WorkInProgress/SoftwareNetworks/Data/Cargo/Master/* $BASEDIR/$BASENAME/ 2>/dev/null

#
# OPTIONAL -- CREATE SMALLER SAMPLE FROM ORIGINAL DATA
#
# ./33_sample_network.py $BASEDIR/$BASENAME/ dependencies_Cargo-repo2-matched-lcc.csv dependencies_Cargo-repo2-matched-lcc 0.01

#
# STEP 1 -- COMPUTE EQUILIBRIA
#
# ./90_compute_equilibrium.py $BASEDIR/$BASENAME/ test2 test2 0.1 4
./90_compute_equilibrium.py $BASEDIR/$BASENAME/ dependencies_Cargo-repo2-matched-lcc-cut2 20_master_Cargo-matched-cut2 0.1 5


# ###########################################################################
#
# PRODUCTION RUN 1.6.0 -- Pypi
#
# ###########################################################################
VERSION=1.6.0-2020-01-12
BASENAME=Pypi-1.6.0
LANGUAGE=Rust
DEPFILE=dependencies_$BASENAME.csv

#
# STEP 0 -- COPY ORIGINAL DATA
#
# mkdir $BASEDIR/$BASENAME/ 2>/dev/null
# cp -R ~/Dropbox/Papers/10_WorkInProgress/SoftwareNetworks/Data/Pypi/Master/* $BASEDIR/$BASENAME/ 2>/dev/null

#
# OPTIONAL -- CREATE SMALLER SAMPLE FROM ORIGINAL DATA
#
# ./33_sample_network.py $BASEDIR/$BASENAME/ dependencies_Pypi-repo2-matched-lcc.csv dependencies_Pypi-repo2-matched-lcc 0.01

#
# STEP 1 -- COMPUTE EQUILIBRIA
#
# ./90_compute_equilibrium.py $BASEDIR/$BASENAME/Master/ test2 test2 0.1 4
# ./90_compute_equilibrium.py $BASEDIR/$BASENAME/ dependencies_Pypi-repo2-matched-lcc 20_master_Pypi-matched 0.1 5
