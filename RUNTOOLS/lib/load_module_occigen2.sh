#!/bin/bash

module load gcc/8.3.0

module load intel/19.4
module load intelmpi/5.1.3.258

module load netcdf-fortran/4.4.4-intel-19.0.4-intelmpi-2019.4.243 
module load netcdf/4.6.3-intel-19.0.4-intelmpi-2019.4.243
module load hdf5/1.10.5-intel-19.0.4-intelmpi-2019.4.243

module load XIOS/2.5_r1903_intelmpi-5.1.3.258

module load NEMOTOOLS/r14615_intelmpi-5.1.3.258

module load nco/4.7.9-gcc-4.8.5-hdf5-1.8.18-openmpi-2.0.4
