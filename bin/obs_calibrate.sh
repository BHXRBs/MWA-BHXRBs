#!/bin/bash

usage()
{
    echo "obs_calibrate.sh [-o obsnum] [-m model] 
    -o  obsnum      : the observation id
    -m  model       : primary calibrator" 1>&2;
exit 1;
}

obsnum=
model=

while getopts 'o:m:' OPTION
do
    case "$OPTION" in
        o)
            obsnum=${OPTARG}
            ;;
        m)
            model=${OPTARG}
            ;;
        ? | : | h)
            usage
            ;;
    esac
done


# if obsid or model is empty then just pring help
if [[ -z ${obsnum} ]]
then
    usage
fi
if [[ -z ${model} ]]
then
    usage
fi


## load configurations
source config.txt

## run template script
script="${MYBASE}/queue/calibrate_${obsnum}.sh"
cat ${base}bin/calibrate.sh | sed -e "s:OBSNUM:${obsnum}:g" \
                                -e "s:BASE:${MYBASE}:g"> ${script}

output="${base}queue/logs/calibrate_${obsnum}.o%A"
error="${base}queue/logs/calibrate_${obsnum}.e%A"
sub="sbatch --begin=now+15 --output=${output} --error=${error} -J calibrate_${obsnum} -M ${MYCLUSTER} ${script} -m ${model}"
jobid=($(${sub}))
jobid=${jobid[3]}

# rename the err/output files as we now know the jobid
error=`echo ${error} | sed "s/%A/${jobid}/"`
output=`echo ${output} | sed "s/%A/${jobid}/"`

echo "Submitted calibrate job as ${jobid}"

