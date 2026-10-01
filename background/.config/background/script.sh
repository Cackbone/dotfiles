#!/bin/bash

bg="$HOME/.local/share/wallpapers/night-city@2x.png"
screencount=$(xrandr --query | grep '\bconnected\b' | wc -l)

for i in $(seq 0 $(($screencount-1)))
do
    echo $i;
    nitrogen --set-zoom-fill $bg --head=$i
done

