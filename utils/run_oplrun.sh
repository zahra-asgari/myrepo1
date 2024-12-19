#!/bin/bash

cd /opt/ibm/ILOG/CPLEX_Studio1210/opl/bin/x86-64_linux/
export LD_LIBRARY_PATH=/opt/ibm/ILOG/CPLEX_Studio1210/opl/bin/x86-64_linux/ 
./oplrun $1 $2 | tee 'opl.log'
