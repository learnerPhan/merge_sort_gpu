#!/bin/bash
if [ "$#" == 3 ]; 
then
	gcc -o alea_generer generateur_alea.c && ./alea_generer $1 $2 $3

else
	echo "<./Alea> <size_A> <size_B> <Borne points>"
        exit 1
fi
