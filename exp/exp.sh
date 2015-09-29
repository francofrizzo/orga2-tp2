#!/bin/bash

repeticiones=1

# Experimento 1
./exp1.sh -n $repeticiones
octave exp1.m

# Experimento 2
./exp2.sh -n $repeticiones

# Experimento 3
./exp3.sh -n $repeticiones

# Experimento 4
./exp4.sh -n $repeticiones
