#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=24
#SBATCH --ntasks-per-node=24
#SBATCH --constraint=HSW24
#SBATCH --threads-per-core=1
#SBATCH -J elmer_occigen
#SBATCH -e elmer_occigen.e%j
#SBATCH -o elmer_occigen.o%j
#SBATCH --time=1:00:00
#SBATCH --exclusive


CONFIG=eORCA025.L121
CASE=OPM018

CONFCASE=${CONFIG}-${CASE}
CTL_DIR=$PDIR/RUN_${CONFIG}/${CONFCASE}/CTL

# Following numbers must be consistant with the header of this job
export NB_NPROC_ELMER=24    # number of cores used for ELMER
export NB_NODES_ELMER=1     # number of cores used for ELMER

date
#
#
echo " Read corresponding include file on the HOMEWORK "
.  ${CTL_DIR}/includefile.sh

. $RUNTOOLS/lib/load_intelmodule.sh

. $RUNTOOLS/lib/function_4_all.sh
. $RUNTOOLS/lib/function_4.sh
. $RUNTOOLS/lib/elmer.sh
