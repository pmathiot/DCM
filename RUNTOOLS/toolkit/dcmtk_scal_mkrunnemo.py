#!/usr/bin/python
# -*- coding: utf-8 -*-
# class = @Scalability experiment tools@

"""
Created on Sun Jun 25 19:18:08 2017
Updated on October 1

@author: Polina, Pierre M.
"""

import os
import argparse
import sys

def parse():
    parser = argparse.ArgumentParser(description=('  PURPOSE:\n'
                                                  '     This python script ends up with a bash script (run.sh) holding\n'
                                                  '     the ad-hoc command lines for submitting a series of simulations\n'
                                                  '     \n'
                                                  '     It assumes that you have already in the local directory an elementary \n'
                                                  '     script launching NEMO and taking 2 online arguments: jpnij, nxios \n'
                                                  '     e.g.  ./run_nemo_occigen_scal.sh 50 3 \n'
                                                  '     \n'), \
                                     epilog     = '--------------------------------------------------------------------\n'
                                                  ' ', \
                                     formatter_class=argparse.RawTextHelpFormatter)

    argreq = parser.add_argument_group('required arguments:')

    argreq.add_argument("--nemo_script"  , metavar='\b', \
                                           help="    <name>           gives script name used to run nemo in scal mode (type: %(type)s, nargs: %(nargs)s, default: %(default)s).", type=str, nargs=1, required=True )
    argreq.add_argument("--core_range"   , metavar='\b', \
                                           help="    <pmin pmax pstp> gives NEMO range of cores to test                (type: %(type)s, nargs: %(nargs)s, default: %(default)s).", type=int, nargs=3, required=True )
    argreq.add_argument("--core_xios"    , metavar='\b', \
                                           help="  <xmin xmax>      gives min/max number of cores dedicated to XIOS (type: %(type)s, nargs: %(nargs)s, default: %(default)s).", type=int, nargs=2, required=True )
    argreq.add_argument("--core_per_node", metavar='\b', \
                                           help="<cpn>            gives number of core per compute node          (type: %(type)s, nargs: %(nargs)s, default: %(default)s).", type=int, nargs=1, required=True )

    return parser.parse_args(args=None if sys.argv[1:] else ['--help'])

def mkrun(script='./run_nemo_occigen_scal.sh', pargs=[50,500,50], xargs=[5,10], cpn=28):

   # proc
   pmin = pargs[0]
   pmax = pargs[1]
   pstp = pargs[2]

   # XIOS proc
   pxmin = xargs[0]
   pxmax = xargs[1]

   # allocate vars to be written
   proc = []
   xios = []

   # read files
   for jp in range(pmin,pmax,pstp):
      proc.append(jp)
      xi = int(jp/cpn + 1)*cpn - jp
      if ( xi < pxmin ):
         xi = xi + cpn          
      if ( xi > pxmax ):
         xi = pxmax
      print(xi, jp, cpn)
      xios.append(xi)

   # write into file
   outfile = './run.sh'
   out = open((outfile),'w')
   out.write('#!/bin/bash'+'\n')
   for i in range(len(xios)):
       out.write(script+' '+str(proc[i])+' '+str(xios[i])+'\n')
   out.close()

if __name__ == "__main__":
   if len(sys.argv) == 1:
    pass #  usage(sys.argv[0])
   args=parse()
   mkrun(args.nemo_script[0],args.core_range,args.core_xios,args.core_per_node[0])
