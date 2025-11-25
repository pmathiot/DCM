#!/bin/bash

# required
# rapatrie ; expatrie ; LookInNamelist ; NEMOTOOLS_DOMAINCFG_PATH ; NEMOTOOLS_REBUILD_PATH

echo Running on $( hostname )
echo NB_NPROC = $NB_NPROC_ELMER
echo NB_NODES = $NB_NODES_ELMER

# initialisation for the use of NEMO function like rapatrie ...
AGRIF=0

if [ ! -d $TMPDIR_ELMER  ]; then mkdir $TMPDIR_ELMER  ; fi

cd $TMPDIR_ELMER

# mkdir MSH and partitioning directory
if [ ! -d MSH/partitioning.$SLURM_NTASKS  ]; then mkdir MSH/; mkdir -p MSH/partitioning.$SLURM_NTASKS ; fi
chmod g+s MSH ; chmod g+s MSH/partitioning.$SLURM_NTASKS ;

echo '(0) define path'
echo '---------------'
echo ''

echo '(1) get all the working tools on the TMPDIR directory'
echo '-----------------------------------------------------'
echo ''

echo "   *** copy db file from $P_CTL_DIR"
cp $P_CTL_DIR/$DBFILE $DBFILE

no=`tail -1 $DBFILE | awk '{print $1}' `
no=$((no-1))
echo "we are running ELMER ice for segment ${no}"
echo ''

echo "   *** copy ocean namelist from $TMPDIR/"
cp $TMPDIR/namelist_oce.${no} namelist_oce.${no}

if (( $no > 1 )) ; then
    ndastpdeb=`tail -2 $DBFILE | head -1 | awk '{print $4}' `
    ndastpbef=`tail -3 $DBFILE | head -1 | awk '{print $4}' `
elif (( $no == 1 )) ; then
    ndastpdeb=`tail -2 $DBFILE | head -1 | awk '{print $4}' `
    ndastpbef=$(LookInNamelist nn_date0 namelist_oce.${no})
else
    echo ''
    echo ' ERROR, Elmer should be run after the first NEMO segment runs'
    echo ''
    exit 42
fi

echo ""
echo "           ***  Intial date for this run : $ndastpdeb"
echo ''

nit000=`tail -2 $DBFILE | head -1 | awk '{print $2}' `
nitend=`tail -2 $DBFILE | head -1 | awk '{print $3}' `
rdt=$(LookInNamelist rn_Dt namelist_oce.${no})
rdt=`echo 1 | awk "{ rdt=int($rdt); print rdt}" `
ndays=` echo 1 | awk "{ a=int( ($nitend - $nit000 +1)*$rdt /86400.) ; print a }" `
echo "           ***  ELMER coupling frequency is : ${ndays}d "

    TAGIN=${ndastpbef}.$((no-1))
    RSTDIRIN=$DDIR/${CONFIG_CASE}-RST.$((no-1))

    TAGOUT=${ndastpdeb}.${no}
    RSTDIROUT=$DDIR/${CONFIG_CASE}-RST.${no}
    OUTDIR=$DDIR/${CONFIG_CASE}-XIOS.${no}

echo ''
echo '(2) Set up the namelist for this run from template'
echo '--------------------------------------------------'
echo ''

echo " [2.1]  elmer sif and param files"
echo " ================================"
echo ''
\cp $P_CTL_DIR/elmer_incf.${CONFIG_CASE} elmer.incf
sed  -e "s@<RUNNAME>@${CONFIG_CASE}_elmer.${no}@g"    \
     -e "s@<MELTFILE>@isfmelt-${no}_${ndays}d_elmer_drown.nc@g"  \
     -e "s@<MELTVAR>@${ISFMELTvar}@g"               \
     -e "s@<ELMER_DTA_DIR>@${P_ELM_DIR}@g" elmer.incf > zincf
\cp zincf elmer.incf

\cp $P_CTL_DIR/elmer_param.${CONFIG_CASE} elmer.param

\cp $P_CTL_DIR/elmer_lsol.${CONFIG_CASE} elmer.lsol

\cp $P_CTL_DIR/elmer_sif.${CONFIG_CASE} elmer.sif
sed  -e "s@<ID-1>@elmer_rst_${TAGIN}@g"                    \
     -e "s@<ELMERDATADIR>@${P_ELM_DIR}@g"                  \
     -e "s@<MESH>@${ELMERMESH}@g"                          \
     -e "s@<ELMERTONEMO>@${ELMERTONEMO}@g"                 \
     -e "s@<ISFDRAFT>@isfdraft_${TAGOUT}_elmer.nc@g"       \
     -e "s@<RSTFILEa>@elmer_rst_${TAGIN}.result@g"         \
     -e "s@<RSTFILEb>@elmer_rst_${TAGOUT}.result@g"        \
     -e "s@<OUTINITMIP>@${CONFIG_CASE}_elmer_${TAGOUT}.${ndays}d_INITMIP.dat@g"  \
     -e "s@<OUTSCAL>@${CONFIG_CASE}_elmer_${TAGOUT}.${ndays}d_scal.dat@g"        \
     -e "s@<OUTFILE>@${CONFIG_CASE}_elmer_${TAGOUT}.${ndays}d.vtu@g" elmer.sif  > zsif
\cp zsif elmer.sif

echo "name      : ${CONFIG_CASE}_elmer.${no}"
echo "mesh      : $ELMERMESH"
echo "melt file : isf_melt_${TAGOUT}.nc"
echo "start file: elmer_rst_${TAGIN}"

echo ''
echo " [2.2]  domain cfg namelist"
echo " =========================="
echo ''

\cp $P_CTL_DIR/namelist_dom.${CONFIG_CASE} namelist_dom

sed -e "s@<CN_FISFD>@isfdraft_${TAGOUT}.nc@" \
    -e "s@<CN_FBATHY>@isfdraft_${TAGOUT}.nc@"          \
    -e "s@<CN_FCOORD>@$COORDINATE@"          \
    -e "s@<CONFCASE>@${CONFIG_CASE}@"  namelist_dom > znamelist1
\cp znamelist1 namelist_dom

echo ''
echo ' [2.3]   Set flags according to namelists'
echo " ========================================"
echo ''

# Iceberg calving
ICB=0
tmp=$(LookInNamelist ln_icebergs  namelist_oce.${no}) ; tmp=$(normalize $tmp)
if [ $tmp = T ] ; then
    ICB=1
    echo '      *** iceberg lagrangian model ON'
    echo "          - iceberg calving will be store here: $RSTDIRIN"
else
    echo '      *** iceberg lagrangian model OFF'
fi

# Mesh mask
MSH=$(LookInNamelist nn_msh   namelist_dom) ;
if [[ $MSH == 1 ]] ; then
    echo '      *** mesh mask output ON'
else
    echo '      E R R O R: NEMO mesh mask are not available => stop'
    echo '      S O L U T I O N: set nn_msh in namelist_dom.'
    exit 42
fi

echo ''
echo '(3) Look for input files (According to flags)'
echo '---------------------------------------------'
echo ''
echo ' [3.1] : configuration files'
echo ' ==========================='
echo ''

echo ''
echo ' [3.2] : Geometry fields'
echo ' ======================='
echo ''
echo '   [3.2.1] : get bathymetry'
echo ''
         rapatrie $BATHYMETRY $P_I_DIR $F_DTA_DIR $BATHYMETRY

echo ''
echo '   [3.2.2] : get coordinates'
echo ''
         CN_COORD=$(LookInNamelist cn_fcoord namelist_dom)
         rapatrie $CN_COORD $P_I_DIR $F_DTA_DIR $CN_COORD
echo ''
echo ' [3.4] : restart files'
echo ' ====================='

    if [ $no -eq  1 ] ; then
        echo '   ***  Rapatrie elmer initial condition.'
        for zfile in `ls $ELMER_INI_PATH/$ELMERINI.*`; do
           file=`basename $zfile`
           ifile=${file#*result.}
           rapatrie $file $ELMER_INI_PATH NONE MSH/elmer_rst_${TAGIN}.result.$ifile
        done
    else
        echo '   ***  Rapatrie elmer restart.'
        for zfile in `ls $RSTDIRIN/elmer_rst_${TAGIN}.result.*`; do
           file=`basename $zfile`
           rapatrie $file $RSTDIRIN NONE MSH/$file
        done
    fi

echo ''
echo ' [3.5] : mask files'
echo ' =================='

    if [ $no -eq  1 ] ; then
        echo '   ***  Rapatrie initial mesh_mask.'
        rapatrie $file ${MESHMASK} NONE ${NEMO_MESHMASK}_${TAGIN}.nc
    else
        echo '   ***  Rapatrie mesh_mask from restart.'
        rapatrie ${NEMO_MESHMASK}_${TAGIN}.nc $RSTDIRIN NONE ${NEMO_MESHMASK}_${TAGIN}.nc
    fi

echo ''
echo ' [3.6] : get elmer grid'
echo ' ======================'
echo ''

     for zfile in `ls $ELMER_PART_PATH/part.*`; do
        file=`basename $zfile`
        rapatrie $file $ELMER_PART_PATH NONE MSH/partitioning.$SLURM_NTASKS/$file
     done

echo ''
echo ' [3.7] : NEMO to ELMER files (melt, grid and weights)"'
echo ' ====================================================='
echo ''
echo "    *** melt is extracted from $RSTDIROUT"

    # This is RSTDIROUT because it comes from the previous NEMO
    rapatrie isfmelt-${no}_${ndays}d.nc $RSTDIROUT NONE isf_melt_${TAGOUT}.nc
    rapatrie $ELMERCDOgrid ${P_ELM_DIR} NONE $ELMERCDOgrid
    rapatrie $NEMOCDOgrid ${P_I_DIR} NONE $NEMOCDOgrid
    rapatrie $NEMOtoELMERwght ${P_I_DIR} NONE $NEMOtoELMERwght

if [[ $LMELTEXTRAPOLATION == 1 ]]; then
    echo "    *** extrapolate isf_melt_${TAGOUT}.nc (ie very basic parametrisation of non resolved cell)"
    ${SOSIE_PATH}/mask_drown_field.x -D -i isf_melt_${TAGOUT}.nc -v soisfmelt_elmer -x nav_lon -y nav_lat -z depth -t time_counter -m 0 -p 1 -g 100 -o isf_melt_${TAGOUT}_drown.nc || exit 42
else
    echo "    *** raw melt from NEMO is used"
fi

echo "    *** compute interpolation of isf_melt_${TAGOUT}_drown.nc onto ELMER grid"

echo "             - cp NEMOCDO grid to tmp file"
    tmpfile=ztmp.nc
    \cp $NEMOCDOgrid $tmpfile                                                                     || exit 42

echo "             - add melt data to tmp file"
    ncks -A -C -v ${ISFMELTvar} isf_melt_${TAGOUT}_drown.nc $tmpfile                              || exit 42

echo "             - update coordinate attribute"
    ncatted -a coordinates,${ISFMELTvar},m,c,"lon lat" $tmpfile                                   || exit 42

echo "             - set fill value to 0 and delete it because 0 is a valid data for melt"
    ncatted -a missing_value,${ISFMELTvar},m,f,0.0 -a _FillValue,${ISFMELTvar},m,f,0.0 $tmpfile   || exit 42
    ncatted -a missing_value,${ISFMELTvar},d,,     -a _FillValue,${ISFMELTvar},d,, $tmpfile       || exit 42

echo "             - compute the interpolation"
    cdo remap,$ELMERCDOgrid,$NEMOtoELMERwght -selname,${ISFMELTvar} $tmpfile isfmelt-${no}_${ndays}d_elmer_drown.nc || exit 42

echo "             - change the _fillvalue for Elmer"
    ncatted -a _FillValue,${ISFMELTvar},m,f,-9999 isfmelt-${no}_${ndays}d_elmer_drown.nc                            || exit 42

echo ''
echo ' [3.7] : ELMER to NEMO files (melt, grid and weights)"'
echo ' ====================================================='
echo ''
echo '    *** get ELMER to NEMO netcdf file (eindex)'
     
     rapatrie $ELMERTONEMO ${P_ELM_DIR} NONE $ELMERTONEMO

echo ''
echo ' [3.8] : get ELMER solvers'
echo ' ========================='
echo ''

    \cp $ELMER_SOL_PATH/* .

touch donecopy

echo '(4) Run the code'
echo '----------------'
echo ''

date
echo elmer.sif > ELMERSOLVER_STARTINFO

echo "    run Elmer: $ELMER_HOME/bin/ElmerSolver_mpi"

module purge
module load c/intel/19.0.5.281 c++/intel/19.0.5.281 fortran/intel/19.0.5.281 intel/19.0.5.281 mpi/openmpi/4.0.2
module load flavor/buildcompiler/intel/19 flavor/buildmpi/openmpi/4.0 flavor/hdf5/parallel
module load netcdf-c/4.6.0 netcdf-fortran/4.4.4
module load cmake/3.16.5
module load ELMER/Elmer_v9.0_r21ddff3a

ccc_mprun $ELMER_HOME/bin/ElmerSolver_mpi
#srun --mpi=pmi2 -K1 --resv-ports -n $NB_NPROC_ELMER $ELMER_HOME/bin/ElmerSolver_mpi
STOP_FLAG=$?
date

module purge
module load cdo
module load nco
module load DCM/DCM_v4.2.0_TIPACCS_shared
module load NEMOTOOLS/r14615.2_intel20.0.0_openmpi4.0.2

echo ''
echo '(5) Post processing of the run'
echo '------------------------------'

date
echo ' [5.1] check the status of the run'
echo ' ================================'

date
  # Post process the run according to the STOP_FLAG
case $STOP_FLAG in
    ( 0 )
    echo ''
    echo "   ***  Run OK"
    echo ''
    echo "   ***  Restart dir  is $RSTDIROUT"
    echo "   ***  Output  dir  is $OUTDIR"
    echo "   ***  Tag     ext. is $TAGOUT"
    echo ''
    echo ' [5.2] manage restart files'
    echo ' ==============================='
    date
    \cp MSH/elmer_rst_${TAGOUT}.result.* $RSTDIROUT/.  || exit 42
    date
    echo ' [5.4] Rename namelists, icesheet.output and other text files. Copy to P_S_DIR'
    echo ' ============================================================================='
    date
    echo ''
    echo '(6) : Final Post Processing after next run is queued'
    echo '----------------------------------------------------'
    echo ''
    date 
    echo ' [6.1] Process the vtu files'
    echo ' ==========================='
    date

    if [ ! -d $OUTDIR/ist_OUTPUT ]; then mkdir $OUTDIR/ist_OUTPUT ; fi

    \cp MSH/${CONFIG_CASE}_elmer_${TAGOUT}.${ndays}d_*np*_t????.*vtu $OUTDIR/ist_OUTPUT/.        || exit 42
    \cp MSH/${CONFIG_CASE}_elmer_${TAGOUT}.${ndays}d_t????.pvtu $OUTDIR/ist_OUTPUT/.             || exit 42
    \cp Basin??_${CONFIG_CASE}_elmer_${TAGOUT}.${ndays}d_INITMIP.dat* $OUTDIR/ist_OUTPUT/.       || exit 42
    \cp _${CONFIG_CASE}_elmer_${TAGOUT}.${ndays}d_INITMIP.dat.names $OUTDIR/ist_OUTPUT/Basin_${CONFIG_CASE}_elmer_${TAGOUT}.${ndays}d_INITMIP.dat.names || exit 42
    \cp ${CONFIG_CASE}_elmer_${TAGOUT}.${ndays}d_scal.dat* $OUTDIR/ist_OUTPUT/.                  || exit 42

    date
    echo ''
    echo ' [6.2] Process the next NEMO input files '
    echo ' ======================================= '
    echo ''
    echo '     [6.2.1] prepare ice shelf draft'
    echo ''
        python ${ELMER2NEMO_PATH}/ELMERtoNEMO_prepare_bathy.py --fNEMObathy ${BATHYMETRY}               \
							       --vNEMObathy Bathymetry_isf              \
							       --fELMERisfd isfdraft_${TAGOUT}_elmer.nc \
							       -o isfdraft_${TAGOUT}.nc                 || exit 42
    echo ''
    echo '     [6.2.2] compute new domain_cfg file'
    echo ''
        date
        cp namelist_dom namelist_cfg
        cp namelist_dom namelist_ref
        
        time ccc_mprun ${NEMOTOOLS_DOMAINCFG_PATH}/make_domain_cfg.exe 
        if [[ $? != 0 ]]; then echo '';echo 'error in make_domain_cfg.exe'; echo '';exit 42; else echo 'make_domain_cfg.exe finished correctly'; fi
        cp namelist_dom ${CONFIG_CASE}_namelist_dom_${TAGOUT}
        cp ocean.output ${CONFIG_CASE}_domain.output_${TAGOUT}
        date
    echo ''
    echo '     [6.2.3] rebuild domain_cfg file'
    echo ''
        date
        time ${NEMOTOOLS_REBUILD_PATH}/rebuild_nemo -d 1 -x 200 -y 200 -z 1 -t 1 domain_cfg $NB_NPROC_ELMER
        if [[ $? != 0 ]]; then echo '';echo 'error in rebuild domain_cfg.nc'; echo '';exit 42; fi
        date
    echo ''
    echo '     [6.2.4] rebuild mesh mask file'
    echo ''
        date
           time ${NEMOTOOLS_REBUILD_PATH}/rebuild_nemo -d 1 -x 200 -y 200 -z 1 -t 1 mesh_mask $NB_NPROC_ELMER
           if [[ $? != 0 ]]; then echo '';echo 'error in rebuild mesh_mask.nc'; echo '';exit 42; fi
        date
    echo ''
    echo '     [6.2.5] add mask variable to domain_cfg file (usefull for post processing)'
    echo ''
        date
           ncks -A -v tmask,umask,vmask,fmask,tmaskutil,umaskutil,vmaskutil mesh_mask.nc domain_cfg.nc
           if [[ $? != 0 ]]; then echo ''; echo 'error in copying mask variable in domain_cfg';  echo '';exit 42; fi
        date
    echo ''
    echo '     [6.2.6] compute calving file'
    echo ''
    if [[ $ICB == 1 ]]; then
        date
        PVTUFILE=`ls MSH/${CONFIG_CASE}_elmer_${TAGOUT}.${ndays}d_t????.pvtu`
        time ${ELMER2NEMO_PATH}/ELMERtoNEMO_calving.py --fELMERvtu $PVTUFILE     \
						      --fNEMOcoord domain_cfg.nc \
						      --fNEMOmask  domain_cfg.nc \
						      -o           icb_calving_${TAGOUT}.nc
        if [[ $? != 0 ]]; then echo 'error in ELMERtoNEMO_calving.py'; exit 42; fi
        cp icb_calving_${TAGOUT}.nc $RSTDIROUT/icb_calving_${TAGOUT}.nc    || exit 42 # copy in restart dir
        cp icb_calving_${TAGOUT}.nc ${TMPDIR}/icb_calving_${TAGOUT}.nc     || exit 42 # copy in TMPDIR ready for next run
        date
    else
        echo ' nothing to do, iceberg OFF'
    fi
    echo ''
    echo '     [6.2.7] move and copy domain file'
    echo ''
    echo "             *** copy domain_cfg.nc to $RSTDIROUT/${NEMO_DOMAINCFG}_${TAGOUT}.nc"
    date
    mv domain_cfg.nc ${NEMO_DOMAINCFG}_${TAGOUT}.nc                              || exit 42
    mv mesh_mask.nc  ${NEMO_MESHMASK}_${TAGOUT}.nc                              || exit 42
    cp ${NEMO_DOMAINCFG}_${TAGOUT}.nc $RSTDIROUT/${NEMO_DOMAINCFG}_${TAGOUT}.nc  || exit 42 # copy in restart dir
    cp ${NEMO_MESHMASK}_${TAGOUT}.nc  $RSTDIROUT/${NEMO_MESHMASK}_${TAGOUT}.nc  || exit 42 # copy in restart dir
    cp ${NEMO_DOMAINCFG}_${TAGOUT}.nc ${TMPDIR}/${NEMO_DOMAINCFG}_${TAGOUT}.nc   || exit 42 # copy in TMPDIR ready for next run
    date
    echo ''
    echo ' [6.3] Pack some files in annex tar file for archiving on F machine'
    echo ' =================================================================='
        nerr=0
        echo ''
        date
        echo ''
        echo "    *** tar ${NEMO_MESHMASK}_${TAGOUT}.nc ${NEMO_DOMAINCFG}_${TAGOUT}.nc isfdraft_${TAGOUT}.nc as geometry file"    
        tar -cvf ${CONFIG_CASE}_nemo_geo_${TAGOUT}.tar ${NEMO_DOMAINCFG}_${TAGOUT}.nc isfdraft_${TAGOUT}.nc || nerr=$((nerr+1))

        echo "    *** add elmer calving (if needed) to rst tar file"
        if [[ $ICB == 1 ]] ; then tar -rvf ${CONFIG_CASE}_nemo_geo_${TAGOUT}.tar icb_calving_${TAGOUT}.nc || nerr=$((nerr+1)) ; fi

        echo "    *** tar elmer restart file"
        tar -cvf ${CONFIG_CASE}_elmer_rst_${TAGOUT}.tar MSH/elmer_rst_${TAGOUT}.result.* || nerr=$((nerr+1))

        echo '    *** job output, namelist_dom, sif file'
        cp elmer.sif      ${CONFIG_CASE}_elmer_${TAGOUT}.sif
        cp elmer.param    ${CONFIG_CASE}_elmer_${TAGOUT}.param
        cp elmer.incf     ${CONFIG_CASE}_elmer_${TAGOUT}.incf
        tar -cvf ${CONFIG_CASE}_elmer_annex_${TAGOUT}.tar ${CONFIG_CASE}_domain.output_${TAGOUT} \
							  ${CONFIG_CASE}_namelist_dom_${TAGOUT}  \
							  ${CONFIG_CASE}_elmer_${TAGOUT}.sif     \
							  ${CONFIG_CASE}_elmer_${TAGOUT}.param   || nerr=$((nerr+1))

        echo '    *** expatrie tar files'
        expatrie ${CONFIG_CASE}_nemo_geo_${TAGOUT}.tar    $F_R_DIR ${CONFIG_CASE}_nemo_geo_${TAGOUT}.tar     || nerr=$((nerr+1))
        expatrie ${CONFIG_CASE}_elmer_rst_${TAGOUT}.tar   $F_R_DIR ${CONFIG_CASE}_elmer_rst_${TAGOUT}.tar    || nerr=$((nerr+1))
        expatrie ${CONFIG_CASE}_elmer_annex_${TAGOUT}.tar $F_S_DIR ${CONFIG_CASE}_elmer_annex_${TAGOUT}.tar  || nerr=$((nerr+1))
        
        echo''
        if (( $nerr > 0 )); then echo "         *** E R R O R in [6.3] ***"; exit 42; fi
        echo ''
        date
        echo ''
        echo ' ELMER segment successful'
    ;;

    ( * )

    date
    echo ' [6.0] ERROR in ELMER'
    echo '====================='
    echo ''
    echo "   *** exit status of elmer is $STOP_FLAG"
    echo ''
    echo "   ===  ERROR : final exit "
    exit $STOP_FLAG
    ;;
esac

exit $STOP_FLAG
