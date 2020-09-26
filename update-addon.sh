#!/bin/bash
if [ $# -eq 0 ] 
	then
	echo "No reason for addon update supplied"
	exit 1
fi

echo "Creating GMA: "
sh ./create-gma.sh

echo "Uploading to the Workshop"
"C:/Program Files (x86)/Steam/steamapps/common/GarrysMod/bin/gmpublish.exe" update -addon "./temp.gma" -id "590788321" -changes $1

