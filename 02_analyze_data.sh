#!/usr/bin/env bash
BASEDIR=~/Dropbox/Papers/10_WorkInProgress/SoftwareProductionNetworks/Data/
# BASEDIR=~/Downloads/
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
# STEP 1 -- PREPARE ORIGINAL DATA
#
# ./33_sample_network.py $BASEDIR/$BASENAME/Master/ dependencies_Cargo-repo2-matched-lcc.csv dependencies_Cargo-repo2-matched-lcc 0.01

#
# STEP 2 -- COMPUTE EQUILIBRIA
#
./90_compute_equilibrium.py $BASEDIR/$BASENAME/Master/ sampled-0.01_dependencies_Cargo-repo2-matched-lcc sampled-0.01_20_master_Cargo-matched 0.5
