#!/bin/sh

LD_LIBRARY_PATH=/Applications/CPLEX_Studio1210/opl/bin/x86-64_osx
export LD_LIBRARY_PATH

exec ${SHELL:-/bin/zsh}  $*