#!/bin/bash

module load singularity/4.1.0-slurm

#download the required containers
singularity pull docker://steveprabu/mwa-reduce:amd64
singularity pull docker://mwatelescope/aoflagger:3.0_portable
singularity pull docker://mwatelescope/hyperdrive:main
singularity pull docker://alecthomson/wsclean:v3.5

#download the beam model
wget http://ws.mwatelescope.org/static/mwa_full_embedded_element_pattern.h5

