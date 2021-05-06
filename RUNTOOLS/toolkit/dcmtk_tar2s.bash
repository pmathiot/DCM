#!/bin/bash
#SBATCH --mem=2G
#SBATCH --time=1440
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --constraint HSW24

# description of the tar (-d option)
if [ $# != 5 ] ; then echo "usage: dcmtk_tar2s.sh [CONFIG] [CASE] [FREQ] [YEARB] [YEARE]"; exit 42; fi

CONFIG=$1
CASE=$2
FREQ=$3
YEARB=$4
YEARE=$5

# test data directory
if [ ! -d $DDIR/$CONFIG/${CONFIG}-${CASE}-S/$FREQ ]; then 
   $echo 'E R R O R: $DDIR/$CONFIG/${CONFIG}-${CASE}-S/$FREQ does not exist'; exit 42
else
   cd $DDIR/$CONFIG/${CONFIG}-${CASE}-S/$FREQ
fi

# test store dir tree
if [ ! -d $SDIR/$CONFIG/${CONFIG}-${CASE}-S/$FREQ ]; then 
   echo "$SDIR/$CONFIG/${CONFIG}-${CASE}-S/$FREQ is missing; we create it"
   mkdir -p $SDIR/$CONFIG/${CONFIG}-${CASE}-S/$FREQ
fi

for YEAR in `ls -d $(eval echo {$YEARB..$YEARE})`; do 
   echo "tar year: $YEAR ..."
   echo ''
   if [[ ! -f $SDIR/$CONFIG/${CONFIG}-${CASE}-S/$FREQ/${FREQ}_${YEAR}.tar ]]; then
      tar -cvf $SDIR/$CONFIG/${CONFIG}-${CASE}-S/$FREQ/${FREQ}_${YEAR}.tar $YEAR
      if [[ $? != 0 ]]; then 
         echo "E R R O R during tar of ${FREQ}_${YEAR}.tar"
      else
         echo "S U C C E E D of ${FREQ}_${YEAR}.tar"
      fi
   else
      echo "$SDIR/$CONFIG/${CONFIG}-${CASE}-S/$FREQ/${FREQ}_${YEAR}.tar is already present"
      echo "       double check and clean SDIR before restarting the script."
   fi
   echo ''
   echo ''
done
