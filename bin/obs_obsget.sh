#!/bin/bash

usage()
{
    echo "obs_getobs.sh [-o obsnum] [-s slurm id] 
    -o  obsnum      : the observation id
    -s  slurm id    : slurm id from ASVO" 1>&2;
exit 1;
}

obsnum=
slurmID=

while getopts 'o:s:' OPTION
do
    case "$OPTION" in
        o)
            obsnum=${OPTARG}
            ;;
        s)
            slurmID=${OPTARG}
            ;;
        ? | : | h)
            usage
            ;;
    esac
done


# if obsid or slurmID is empty then just pring help
if [[ -z ${obsnum} ]]
then
    usage
fi
if [[ -z ${slurmID} ]]
then
    usage
fi


## load configurations
source config.txt

## run template script
script="${MYBASE}/queue/obsget_${obsnum}.sh"
cat ${base}bin/obsget.sh | sed -e "s:OBSNUM:${obsnum}:g" \
                                -e "s:BASE:${MYBASE}:g"> ${script}

output="${base}queue/logs/obsget_${obsnum}.o%A"
error="${base}queue/logs/obsget_${obsnum}.e%A"
sub="sbatch --begin=now+15 --output=${output} --error=${error} -J obsget_${obsnum} -M ${MYCLUSTER} ${script} -s ${slurmID}"
jobid=($(${sub}))
jobid=${jobid[3]}

# rename the err/output files as we now know the jobid
error=`echo ${error} | sed "s/%A/${jobid}/"`
output=`echo ${output} | sed "s/%A/${jobid}/"`

echo "Submitted obsget job as ${jobid}"

