#!/bin/bash -l
#SBATCH --export=NONE
#SBATCH --partition=mwa
#SBATCH --account=mwasci
#SBATCH --ntasks=8
#SBATCH --mem=16GB
#SBATCH --time=8:00:00
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
slurmID=

source ${myPath}/aliases

while getopts 's:' OPTION
do
    case "$OPTION" in
        s)
            slurmID=${OPTARG}
            ;;
    esac
done


cd ${base}/processing/
mkdir ${obsnum}
cd ${obsnum}

## download file
outfile="${obsnum}.ms"
if [[ -e "${outfile}" ]]; then
    echo "${outfile} exists, not downloading again"
else
    mv /scratch/mwasci/asvo/${slurmID}/*.tar ${base}/processing/${obsnum}
fi

# untar the file
tar -xvf ${obsnum}*.tar

end=`date +%s`
runtime=$((end-start))
echo "the job run time ${runtime}"

}
