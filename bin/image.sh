#!/bin/bash -l
#SBATCH --export=NONE
#SBATCH --partition=mwa
#SBATCH --account=mwasci
#SBATCH --ntasks=32
#SBATCH --mem=64GB
#SBATCH --time=18:00:00
#SBATCH --mail-type FAIL,TIME_LIMIT
#SBATCH --mail-user sirmcmissile47@gmail.com


start=`date +%s`

module load singularity/4.1.0-slurm
shopt -s expand_aliases
source /scratch/mwasci/sprabu/MWA-BHXRBs/aliases

set -x
{

obsnums=()
base=BASE
imgname=
calobs=

source ${myPath}/aliases

while getopts 'o:n:c:' OPTION
do
    case "$OPTION" in
        o)
	    obsnums+=("${OPTARG}")
            ;;
	n)
	    imgname=${OPTARG}
	    ;;
	c)
	    calobs=${OPTARG}
	    ;;
    esac
done


cd ${base}/processing/

## step1) applysolutions and flat ants
for obsnum in "${obsnums[@]}"; do

    cd ${obsnum}
    applysolutions ${obsnum}.ms ../${calobs}/${calobs}.bin
    cd ../
done

## step2) make image
cd ${base}/images/

msfiles=()
for obsnum in "${obsnums[@]}"; do
    msfiles+=("../processing/${obsnum}/${obsnum}.ms")
done

wsclean -name ${imgname}-brigs0 -size 2000 2000 -scale 0.5amin -niter 10000000 -mgain 0.4 -weight briggs 0 -auto-threshold 1.5 -gridder wgridder -pol i -minuv-l 20 -mwa-path ${base}/containers/ -apply-primary-beam ${msfiles[@]}

wsclean -name ${imgname}-natural -size 2000 2000 -scale 0.5amin -niter 10000000 -mgain 0.4 -weight natural -auto-threshold 1.5 -gridder wgridder -pol i -minuv-l 20 -mwa-path ${base}/containers/ -apply-primary-beam ${msfiles[@]}


end=`date +%s`
runtime=$((end-start))
echo "the job run time ${runtime}"

}
