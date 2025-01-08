#!/bin/bash

declare -a array=("First" "Second" "Third")

for item in ${array[@]}; do
    echo $item
done