#!/bin/bash

bg="/home/cedric/.config/background/images/bg-purple-gradient.jpg"
screencount=$(xrandr --query | grep '\bconnected\b' | wc -l)

for i in $(seq 0 $(($screencount-1)))
do
    echo $i;
    nitrogen --set-auto $bg --head=$i
done

