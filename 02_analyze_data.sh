#!/usr/bin/env bash
BASEDIR=~/Dropbox/Papers/10_WorkInProgress/VulnerabilityContagion/Data/
GITDIR=~/Git/SoftwareProductionNetworks/

# ###########################################################################
#
# PRODUCTION RUN 1.6.0 -- NPM
#
# ###########################################################################
VERSION=1.6.0-2020-01-12
BASENAME=NPM-1.6.0Wyss
LANGUAGE=JavaScript
DEPFILE=dependencies_$BASENAME.csv

#
# STEP 0 -- COPY ORIGINAL DATA
#
# mkdir $BASEDIR/$BASENAME/ 2>/dev/null
# cp -R ~/Downloads/NPM/Master/* $BASEDIR/$BASENAME/ 2>/dev/null

#
# OPTIONAL -- CREATE SMALLER SAMPLE FROM ORIGINAL DATA
#
# ./33_sample_network.py $BASEDIR/$BASENAME/ dependencies_Cargo-repo2-matched-lcc.csv dependencies_Cargo-repo2-matched-lcc 0.01

#
# STEP 1 -- COMPUTE  + ANALYZE EQUILIBRIA
#
./90_compute_equilibrium.py $BASEDIR/$BASENAME/ repo_dependencies_NPM-matchedWyss+newIDs Wyss_npm_data5 0.005 5

# for theta in 0.0001 0.001 0.005
# do
#     ./90_compute_equilibrium.py $BASEDIR/$BASENAME/ dependencies_Cargo-repo2-matched-lcc-cut2 20_master_Cargo-matched-cut2 $theta 5
# done




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
# ./90_compute_equilibrium.py $BASEDIR/$BASENAME/ dependencies_Cargo-repo2-matched-lcc-cut2 20_master_Cargo-matched-cut2 0.1 5

# for theta in 0.0001 0.001 0.005 0.01 0.05 0.1 0.15 0.2 
# do
#     ./90_compute_equilibrium.py $BASEDIR/$BASENAME/ dependencies_Cargo-repo2-matched-lcc-cut2 20_master_Cargo-matched-cut2 $theta 5
# done

#
# OPTIONAL -- CREATE SAMPLE NETWORKS AND ANALYZE THEM TO UNDERSTAND MODEL
#

# for i in 32 64 128 256 512 1024
#     do ./34_create_sample_networks.py $BASEDIR/$BASENAME/test/ test $i 0.0 0.0
# done

# NETWORKS: star_in star_out complete 
# for NETID in star_in star_out complete 
#     do for DISTID in log_normal equal 
#         do for i in 32 64 128 256 512 1024
#             do ./90_compute_equilibrium.py $BASEDIR/$BASENAME/test/ test-$NETID-$i test_theta-$DISTID-$i 0.05 1 ; cd $BASEDIR/$BASENAME/test/ ; cat summary_test-$NETID*.csv > summary_test-$NETID-$DISTID.csv ; mv summary_test-$NETID-$DISTID.csv ../ ; cd -
#         done
#     done
# done


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
