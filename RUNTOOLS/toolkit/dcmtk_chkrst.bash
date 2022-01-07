#!/bin/bash
if [[ $# -ne 4 ]] ; then echo 'usage: dcmtk_chkrst CONFIG CASE ISEQS ISEQE'; exit 42; fi

CONFIG=$1
CASE=$2
ISEQS=$3
ISEQE=$4

CONFCASE=${CONFIG}-${CASE}

RSTDIR=$SDIR/$CONFIG/${CONFCASE}-R
CTLDIR=$PDIR/RUN_${CONFIG}/${CONFCASE}/CTL/

##############################################################################
check_presence_restart_tar ()  {
    nmissf=0
    echo ''
    echo " - check presence of the restart tar files ..."
    for iseq in $(seq $ISEQS $ISEQE) ; do
        if [ ! -f $RSTDIR/${CONFCASE}-RST.${iseq}.tar ] ; then
            echo -e "\e[0;31;1m    * segment $iseq : ${CONFCASE}-RST.${iseq}.tar is missing \e[0m"
            nmissf=$((nmissf+1))
        fi
    done
    echo ''
    if [[ $nmissf == 0 ]] ; then 
        echo '    * all restart tar files are in the store directory';
    fi
    echo ''
    return $nmissf
    }

check_job_output_tar_rst () {
    nfailed=0
    echo ''
    echo " - check status of job used to build rst tar archives ..."
    for iseq in $(seq $ISEQS $ISEQE) ; do
        njob=`ls ${CTLDIR}/zsrst.${iseq}.o* 2>/dev/null | wc -l`
        # at least one job output
        if [[ $njob > 0 ]] ; then
            lastjob=`ls -lt ${CTLDIR}/zsrst.${iseq}.o* | head -1`
            lastid=${lastjob#*.o}
            lcompleted=`sacct -j ${lastid} | grep zsrst | grep COMPLETED | wc -l`
            if [[ $lcompleted == 0 ]]; then
                echo -e "\e[0;31;1m    * segment $iseq : latest job ($lastid) failed \e[0m"
                nfailed=$((nfailed+1))
            fi
        # no job output found
        elif [[ $njob == 0 ]] ; then
            echo -e "\e[0;31;1m    * segment $iseq : cannot check status of job (cannot retreive jobid) \e[0m"
            nfailed=$((nfailed+1))
        fi
    done
    echo ''
    if [[ $nfailed == 0 ]]; then
        echo '    * all zsrst used to build the rst tar files are successful';
    fi
    echo ''

    return $nfailed
    }

##############################################################################

echo ''
echo "Check integrity of rst tar file in $RSTDIR for segments between $ISEQS and $ISEQE"

# check presence of the tar file in the store directory
check_presence_restart_tar
nerrfile=$?

# check if the latest job used to rebuild the rst tar archive was successful
check_job_output_tar_rst
nerrtar=$?

nerr=$(( nerrfile + nerrtar ))
if [[ $nerr == 0 ]] ; then
    echo "All rst tar files are on the store and the latest job outputs used to build the archive are successful "
    echo ''
    echo " S U C C E S S "
else
    echo " E R R O R "
fi
echo ''
