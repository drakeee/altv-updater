#!/bin/bash

os="x64_linux"
title="alt:V Server Updater"
download=("binary")

declare -A branches=(
	["release"]="Release"
	["rc"]="Release Candidate"
	["dev"]="Development"
)

declare -A options=(
	["binary"]="Server binary"
	["data"]="Data files"
	["js_module"]="JS Module"
	["csharp_module"]="C# Module"
	["sample"]="Sample config file"
	["example"]="Example resource pack"
)

radio_list=()
for branch in "${!branches[@]}"; do
	radio_list+=("$branch" "${branches[$branch]}" OFF)
done

while true; do
	branch=$(whiptail --title "${title}" --radiolist "Please choose which branch do you want to download:" 10 70 "${#branches[@]}" "${radio_list[@]}" 3>&1 1>&2 2>&3)

	if [ $? == 1 ]; then
		exit 1
		break
	fi

	if [ -z "$branch" ]; then
		continue
	fi

	break

done

options_list=()
for option in "${!options[@]}"; do
	if [ "$option" == "binary" ]; then continue; fi
	options_list+=("$option" "${options[$option]}" OFF)
done

add_options=$(whiptail --title "${title}" --checklist "Please select extra options from the list below:" 15 60 "$((${#options[@]}-1))" "${options_list[@]}" 3>&1 1>&2 2>&3)
if [[ $? == 1 ]]; then
	exit 1
fi

for option in ${add_options[@]}; do
	option="${option%\"}"
	option="${option#\"}"

	download+=($option)
done

declare -A url_binary=(["https://cdn.altv.mp/server/${branch}/${os}/altv-server"]=".")
declare -A url_data=(
	["https://cdn.altv.mp/server/${branch}/${os}/data/vehmodels.bin"]="./data/"
	["https://cdn.altv.mp/server/${branch}/${os}/data/vehmods.bin"]="./data/"
)
declare -A url_js_module=(
	["https://cdn.altv.mp/js-module/${branch}/${os}/modules/js-module/libjs-module.so"]="./modules/js-module/"
	["https://cdn.altv.mp/js-module/${branch}/${os}/modules/js-module/libnode.so.72"]="./modules/js-module/"
)
declare -A url_csharp_module=(
	["https://cdn.altv.mp/coreclr-module/${branch}/${os}/AltV.Net.Host.dll"]="."
	["https://cdn.altv.mp/coreclr-module/${branch}/${os}/AltV.Net.Host.runtimeconfig.json"]="."
	["https://cdn.altv.mp/coreclr-module/${branch}/${os}/modules/libcsharp-module.so"]="./modules/"
)
declare -A url_sample=(["https://github.com/Stuyk/altv-pkg/blob/master/bin/files/server.cfg"]=".")
declare -A url_example=(["https://cdn.altv.mp/samples/resources.zip"]=".")

{
	download_size=${#download[@]}
	i=1
	for d in "${download[@]}"; do
		var="url_$d[@]"
		declare -n arr="url_$d"

		percentage=$(printf "%.0f" "$(echo "scale=1; ${i}/${download_size}*100" | bc)")
		echo -e "XXX\n$percentage\nDownloading ${options[$d]}... \nXXX"

		for b in "${!arr[@]}"; do
			destination=${arr[$b]}

			wget $b -P $destination -q
		done

		if [ "$d" == "sample" ]; then
			unzip resources.zip
			rm resources.zip
		fi

		((i=i+1))
	done
} | whiptail --title "${title}" --gauge "Downloading assets" 8 78 0
