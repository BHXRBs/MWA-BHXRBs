#!/bin/bash -l
#SBATCH --export=NONE
#SBATCH --partition=mwa
#SBATCH --account=mwasci
#SBATCH --ntasks=32
#SBATCH --mem=64GB
#SBATCH --time=12:00:00
#SBATCH --mail-type FAIL,TIME_LIMIT
#SBATCH --mail-user sirmcmissile47@gmail.com


start=`date +%s`

module load singularity/4.1.0-slurm
shopt -s expand_aliases
source /scratch/mwasci/sprabu/MWA-BHXRBs/aliases

set -x
{

obsnum=OBSNUM
base=BASE
model=

source ${myPath}/aliases

while getopts 'm:' OPTION
do
    case "$OPTION" in
        m)
            model=${OPTARG}
            ;;
    esac
done


cd ${base}/processing/
mkdir ${obsnum}
cd ${obsnum}

# step1) run aoflagger
aoflagger ${obsnum}.ms

# step2) round 1 of calibration using calibrator model
calibrate -absmem 60 -m ../../models/model-${model}*withalpha.txt \
	-minuv 60 -maxuv 2600 -ch 4 ${obsnum}.ms round1.bin

# step3) plot initial calibration solutions
plotsolutions round1.bin

# step4) apply initial calibration solution to measurement set
applysolutions ${obsnum}.ms round1.bin

# step5) image using initial calibration solution
wsclean -name round1img -size 2000 2000 -scale 0.5amin -niter 15000 -mgain 0.2 -weight briggs 0 -auto-threshold 1.5 -gridder wgridder ${obsnum}.ms 

# step6) selfcalibration using the MODEL column in ms
calibrate -absmem 60 -minuv 60 -maxuv 2600 -ch 4 ${obsnum}.ms ${obsnum}.bin

# step7) plot self calibrated solutions
plotsolutions ${obsnum}.bin

# step8) applyselfcalibrated solutions back to ms
applysolutions ${obsnum}.ms ${obsnum}.bin

# step9) image the field using the final calibration solution
wsclean -name selfcalibrated-img -size 2000 2000 -scale 0.5amin -niter 15000 -mgain 0.2 -weight briggs 0 -auto-threshold 1.5 -gridder wgridder ${obsnum}.ms


end=`date +%s`
runtime=$((end-start))
echo "the job run time ${runtime}"

}
