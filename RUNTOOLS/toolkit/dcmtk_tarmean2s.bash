#!/bin/bash
#SBATCH --mem=2G
#SBATCH --time=1440
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --constraint HSW24

# description of the tar (-d option)
if [[ $# < 4 ]] ; then echo "usage: dcmtk_tar2s.sh [CONFIG] [CASE] [FREQ] [YEARB] [YEARE]"; exit 42; fi

CONFIG=$1
CASE=$2
FREQ=$3
YEARlst=${@:4}

# test data directory
if [ ! -d $DDIR/$CONFIG/${CONFIG}-${CASE}-MEAN/$FREQ ]; then 
   $echo 'E R R O R: $DDIR/$CONFIG/${CONFIG}-${CASE}-MEAN/$FREQ does not exist'; exit 42
else
   cd $DDIR/$CONFIG/${CONFIG}-${CASE}-MEAN/$FREQ
fi

# test store dir tree
if [ ! -d $SDIR/$CONFIG/${CONFIG}-${CASE}-MEAN/$FREQ ]; then 
   echo "$SDIR/$CONFIG/${CONFIG}-${CASE}-MEAN/$FREQ is missing; we create it"
   mkdir -p $SDIR/$CONFIG/${CONFIG}-${CASE}-MEAN/$FREQ
fi

for YEAR in $YEARlst ; do 
   echo "tar year: $YEAR ..."
   echo ''
   if [[ ! -f $SDIR/$CONFIG/${CONFIG}-${CASE}-MEAN/$FREQ/${FREQ}_${YEAR}.tar ]]; then
      tar -cvf $SDIR/$CONFIG/${CONFIG}-${CASE}-MEAN/$FREQ/${FREQ}_${YEAR}.tar ${YEAR} #${CONFIG}-${CASE}_y${YEAR}*
      if [[ $? != 0 ]]; then 
         echo "E R R O R during tar of ${FREQ}_${YEAR}.tar"
      else
         echo "S U C C E E D of ${FREQ}_${YEAR}.tar"
      fi
   else
      echo "$SDIR/$CONFIG/${CONFIG}-${CASE}-MEAN/$FREQ/${FREQ}_${YEAR}.tar is already present"
      echo "       double check and clean SDIR before restarting the script."
   fi
   echo ''
   echo ''

   if [[ $nerr == 0 ]]; then
      touch $PDIR/RUN_${CONFIG}/${CONFIG}-${CASE}/tar2s_${CONFIG}-${CASE}_${YEAR}.${FREQ}_OK
   else
      touch $PDIR/RUN_${CONFIG}/${CONFIG}-${CASE}/tar2s_${CONFIG}-${CASE}_${YEAR}.${FREQ}_ERR
   fi


done
