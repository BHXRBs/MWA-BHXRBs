#!/bin/bash

usage()
{
    echo "obs_image.sh [-o obsnum] [-n img name] [-c calobs]
    -o  obsnum      : the observation id
    -n  img name    : the name of the image
    -c  calobs      : the calibration observation." 1>&2;
exit 1;
}

obsnums=()
imgname=
calobs=

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
        ? | : | h)
            usage
            ;;
    esac
done


# if obsids,imgname or calobs is empty then just pring help
if [[ -z ${obsnums} ]]
then
    usage
fi
if [[ -z ${imgname} ]]
then
    usage
fi
if [[ -z ${calobs} ]]
then
    usage
fi


## load configurations
source config.txt

newargsobs=()

for obsnum in "${obsnums[@]}"; do
    newargsobs+=(-o "$obsnum")
done


## run template script
script="${MYBASE}/queue/image_${obsnum}.sh"
cat ${base}bin/image.sh | sed -e "s:BASE:${MYBASE}:g"> ${script}

output="${base}queue/logs/image_${obsnum}.o%A"
error="${base}queue/logs/image_${obsnum}.e%A"
sub="sbatch --begin=now+15 --output=${output} --error=${error} -J image_${obsnum} -M ${MYCLUSTER} ${script} -n ${imgname} -c ${calobs} ${newargsobs[@]}"
jobid=($(${sub}))
jobid=${jobid[3]}

# rename the err/output files as we now know the jobid
error=`echo ${error} | sed "s/%A/${jobid}/"`
output=`echo ${output} | sed "s/%A/${jobid}/"`

echo "Submitted image job as ${jobid}"

