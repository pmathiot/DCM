#!/bin/bash

# note that you also need xios2 for compiling the code
#  This NEMO revision was compiled and ran successfully with
# xios rev 1587 of http://forge.ipsl.jussieu.fr/ioserver/svn/XIOS/dev/dev_olga
# to be compiled out of the DCM structure.
#  NEMO fcm files should indicate the xios root directory
#svn co http://forge.ipsl.jussieu.fr/nemo/svn/NEMO/trunk -r 10089 NEMO4
#svn co http://forge.ipsl.jussieu.fr/nemo/svn/NEMO/trunk -r 10374 NEMO4
# as of Jan 29, 2019 :
#svn co -r 10650 https://forge.ipsl.jussieu.fr/nemo/svn/NEMO/releases/release-4.0 NEMO4
# as od May 17, 2019
#svn co -r 10992  https://forge.ipsl.jussieu.fr/nemo/svn/NEMO/releases/release-4.0 NEMO4
# as od May 18, 2019
#svn co -r 10997  https://forge.ipsl.jussieu.fr/nemo/svn/NEMO/releases/release-4.0 NEMO4
# as od May 23, 2019
#svn co -r 11040  https://forge.ipsl.jussieu.fr/nemo/svn/NEMO/releases/release-4.0 NEMO4
# as of June,4  2019
#svn co -r 11075  https://forge.ipsl.jussieu.fr/nemo/svn/NEMO/releases/release-4.0 NEMO4
# as of November, 14 2019
#svn co -r 11902  https://forge.ipsl.jussieu.fr/nemo/svn/NEMO/releases/release-4.0.1 NEMO4
# as of March, 25 2020
#svn co -r 12604  https://forge.ipsl.jussieu.fr/nemo/svn/NEMO/releases/release-4.0.1 NEMO4
# as of March, 27 2020
svn co -r 13358  https://forge.ipsl.jussieu.fr/nemo/svn/NEMO/releases/r4.0/r4.0.3 NEMO4
# cd NEMO4
# svn merge -r 12715:12927 https://forge.ipsl.jussieu.fr/nemo/svn/NEMO/branches/UKMO/NEMO_4.0.2_GO8_package_ENHANCE-02_ISF_nemo
# svn merge --allow-mixed-revisions -r 13243:13276 https://forge.ipsl.jussieu.fr/nemo/svn/NEMO/branches/2020/tickets_2494_2375
# svn merge --allow-mixed-revisions -r 13277:13374 https://forge.ipsl.jussieu.fr/nemo/svn/NEMO/branches/2020/tickets_icb_1900


