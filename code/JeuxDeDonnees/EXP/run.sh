#!/bin/bash
#



for i in $(seq 1 2); do
        echo $i 
    #n=$((2 ** ${i}))
	#    echo $n
	#./nalea $l $h $n
    $1 15 17 100
done
