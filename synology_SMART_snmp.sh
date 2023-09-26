#!/bin/bash
#version 4.5 dated 10/26/2023
#By Brian Wallace

#This script pulls various information from the Synology NAS
#add this script to a scheduled task within Synology task scheduler

#############################################
#VERIFICATIONS
#############################################
#1.) data is collected into influx properly....................................................................................... VERIFIED 3/18/2023
#2.) SNMP errors:
	#a.) bad SNMP user name causes script to shutdown with email.................................................................. VERIFIED 3/18/2023
	#b.) bad SNMP authpass causes script to shutdown with email................................................................... VERIFIED 3/18/2023
	#c.) bad SNMP privacy pass causes script to shutdown with email............................................................... VERIFIED 3/18/2023
	#d.) bad SNMP ip address causes script to shutdown with email................................................................. VERIFIED 3/18/2023
	#e.) bad SNMP port causes script to shutdown with email....................................................................... VERIFIED 3/18/2023
	#f.) error emails a through e above only are sent within the allowed time interval............................................ VERIFIED 3/18/2023
#3.) verify that when "sendmail" is unavailable due, emails are not sent, and the appropriate warnings are displayed.............. VERIFIED 3/18/2023
#4.) verify script behavior when config file is unavailable....................................................................... VERIFIED 3/18/2023
#5.) verify script behavior when config file has wrong number of arguments........................................................ VERIFIED 3/18/2023
#6.) Verify emails are sent when SMART parameters are above, below, or equal to their configured threshold........................ VERIFIED 3/18/2023
#7.) Verify emails are sent when NVME parameters are above, below, or equal to their configured threshold........................ VERIFIED 10/26/2023


#suggest to install the script in Synology web directory on volume1 at /volume1/web/logging/
#if a different directory is desired, change these variables accordingly
config_file_location="/volume1/web/config/config_files/config_files_local"
config_file_name="smart_logging_config.txt"
email_contents="/volume1/web/logging/notifications/SMART_Logging_email_contents.txt"
lock_file_location="/volume1/web/logging/notifications/SMART_Logging.lock"
debug=0

#########################################################
#EMAIL SETTINGS USED IF CONFIGURATION FILE IS UNAVAILABLE
#These variables will be overwritten with new corrected data if the configuration file loads properly. 
email_address="email@email.com"
from_email_address="email@email.com"
#########################################################


#for my personal use as i have multiple Synology systems, these lines can be deleted by other users
######################################################################################
sever_type=1 #1=server2, 2=serverNVR, 3=serverplex

if [[ $sever_type == 1 ]]; then
	config_file_location="/volume1/web/config/config_files/config_files_local"
	config_file_name="smart_logging_config.txt"
fi

if [[ $sever_type == 2 ]]; then
	config_file_location="/volume1/web/logging"
	config_file_name="smart_logging_config.txt"
fi

if [[ $sever_type == 3 ]]; then
	config_file_location="/volume1/web/config/config_files/config_files_local"
	config_file_name="smart_logging_config.txt"
fi

######################################################################################

#create a lock file in the configuration directory to prevent more than one instance of this script from executing  at once
if ! mkdir $lock_file_location; then
	echo "Failed to acquire lock.\n" >&2
	exit 1
fi
trap 'rm -rf $lock_file_location' EXIT #remove the lockdir on exit


########################################
#Send Email Notification Function When Parameters in SMART are "bad"
########################################
# send_mail $disk_SMART_attribute_name $paramter_1_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $email_contents $from_email_address $email_address "has exceeded"
send_mail(){
	# ${1} = $disk_SMART_attribute_name
	# ${2} = $paramter_1_notification_threshold
	# ${3} = $disk_path
	# ${4} = $nas_name
	# ${5} = $disk_SMART_attribute_raw
	# ${6} = $notification_text_file   ($email_contents)
	# ${7} = $from_email_address
	# ${8} = $email_address
	# ${9} = $comparison
	local now=$(date +"%T")
	echo "${1} ${9} its threshold value of ${2} on disk ${3}. It currently is reporting a value of ${5}. Sending Alert Email"
	local mailbody="$now - Warning SMART Attribute ${1} on disk ${3} on ${4} ${9} the threshold value of ${2}. It currently is reporting a value of ${5}"
	echo "from: ${7} " > ${6}
	echo "to: ${8} " >> ${6}
	echo "subject: ${3} SMART ALERT for ${4} " >> ${6}
	echo "" >> ${6}
	echo $mailbody >> ${6}
	if [ $sendmail_installed -eq 1 ]; then	
		local email_response=$(sendmail -t < ${6}  2>&1)
		if [[ "$email_response" == "" ]]; then
			echo -e "\n\nEmail Sent Successfully that SMART attribute is bad\n\n" |& tee -a ${6}
		else
			echo -e "\n\nWARNING -- An error occurred while sending Error email. The error was: $email_response\n\n" |& tee ${6}
		fi	
	else
		echo -e "\n\nERROR -- Could not send alert email that an error occurred getting SNMP data -- command \"sendmail\" is not available\n\n"
	fi
}

#####################################
#Function to send email when SNMP commands fail
#####################################
function SNMP_error_email(){
	local now=$(date +"%T")
	local mailbody="$now - ALERT Synology NAS at IP $nas_url appears to have an issue with SNMP as it returned invalid data. Script \"${0##*/}\" failed"
	echo "from: $from_email_address " > $email_contents
	echo "to: $email_address " >> $email_contents
	echo "subject: ALERT Synology NAS at IP $nas_url appears to have an issue with SNMP " >> $email_contents
	echo "" >> $email_contents
	echo $mailbody >> $email_contents
			
	if [[ "$email_address" == "" || "$from_email_address" == "" ]];then
			echo -e "\n\nNo email address information is configured, Cannot send an email the NAS returned invalid SNMP data"
	else
		if [ $sendmail_installed -eq 1 ]; then	
			local email_response=$(sendmail -t < $email_contents  2>&1)
			if [[ "$email_response" == "" ]]; then
				echo -e "\n\nEmail Sent Successfully that the target NAS appears to have an issue with SNMP" |& tee -a $email_contents
			else
				echo -e "\n\nWARNING -- An error occurred while sending Error email. The error was: $email_response\n\n" |& tee $email_contents
			fi		
		else
			echo -e "\n\nERROR -- Could not send alert email that an error occurred getting SNMP data -- command \"sendmail\" is not available\n\n"
		fi
	fi
	exit 1
}

#verify MailPlus Server package is installed and running as the "sendmail" command is not installed in Synology by default. the MailPlus Server package is required
install_check=$(/usr/syno/bin/synopkg list | grep MailPlus-Server)

if [ "$install_check" = "" ];then
	echo "WARNING!  ----   MailPlus Server NOT is installed, cannot send email notifications"
	sendmail_installed=0
else
	#echo "MailPlus Server is installed, verify it is running and not stopped"
	status=$(/usr/syno/bin/synopkg is_onoff "MailPlus-Server")
	if [ "$status" = "package MailPlus-Server is turned on" ]; then
		sendmail_installed=1
		if [ $debug -eq 1 ];then
			echo "MailPlus Server is installed and running"
		fi
	else
		sendmail_installed=0
		echo "WARNING!  ----   MailPlus Server NOT is running, cannot send email notifications"
	fi
fi
		

if [ -r $config_file_location/$config_file_name ]; then
	#file is available and readable 
	
	#read in file
	read input_read < "$config_file_location/$config_file_name"
	#explode the configuration into an array with the colon as the delimiter
	explode=(`echo $input_read | sed 's/,/\n/g'`)
	
	#verify the correct number of configuration parameters are in the configuration file
	if [[ ! ${#explode[@]} == 80 ]]; then
		echo "WARNING - the configuration file is incorrect or corrupted. It should have 80 parameters, it currently has ${#explode[@]} parameters."
		exit 1
	fi	
	paramter_name=()
	paramter_notification_threshold=()
	paramter_type=()
	
	#save the parameter values into the respective variable and remove the quotes
	SNMP_user=${explode[0]}
	capture_interval=${explode[1]}
	nas_url=${explode[2]}
	nas_name=${explode[3]}
	ups_group=${explode[4]}
	influxdb_host=${explode[5]}
	influxdb_port=${explode[6]}
	influxdb_name=${explode[7]}
	influxdb_user=${explode[8]}
	influxdb_pass=${explode[9]}
	script_enable=${explode[10]}
	AuthPass1=${explode[11]}
	PrivPass2=${explode[12]}
	influx_db_version=${explode[13]}
	influxdb_org=${explode[14]}
	enable_email_notifications=${explode[15]}
	email_address=${explode[16]}
	paramter_name+=(${explode[17]})
	paramter_notification_threshold+=(${explode[18]})
	paramter_name+=(${explode[19]})
	paramter_notification_threshold+=(${explode[20]})
	paramter_name+=(${explode[21]})
	paramter_notification_threshold+=(${explode[22]})
	paramter_name+=(${explode[23]})
	paramter_notification_threshold+=(${explode[24]})
	paramter_name+=(${explode[25]})
	paramter_notification_threshold+=(${explode[26]})
	from_email_address=${explode[27]}
	snmp_auth_protocol=${explode[28]}
	snmp_privacy_protocol=${explode[29]}
	paramter_type+=(${explode[30]})
	paramter_type+=(${explode[31]})
	paramter_type+=(${explode[32]})
	paramter_type+=(${explode[33]})
	paramter_type+=(${explode[34]})
	paramter_type+=(${explode[35]})
	paramter_type+=(${explode[36]})
	paramter_type+=(${explode[37]})
	paramter_type+=(${explode[38]})
	paramter_type+=(${explode[39]})
	paramter_type+=(${explode[40]})
	paramter_type+=(${explode[41]})
	paramter_type+=(${explode[42]})
	paramter_type+=(${explode[43]})
	paramter_type+=(${explode[44]})
	paramter_type+=(${explode[45]})
	paramter_type+=(${explode[46]})
	paramter_type+=(${explode[47]})
	paramter_type+=(${explode[48]})
	paramter_type+=(${explode[49]})
	paramter_name+=(${explode[50]})
	paramter_notification_threshold+=(${explode[51]})
	paramter_name+=(${explode[52]})
	paramter_notification_threshold+=(${explode[53]})
	paramter_name+=(${explode[54]})
	paramter_notification_threshold+=(${explode[55]})
	paramter_name+=(${explode[56]})
	paramter_notification_threshold+=(${explode[57]})
	paramter_name+=(${explode[58]})
	paramter_notification_threshold+=(${explode[59]})
	paramter_name+=(${explode[60]})
	paramter_notification_threshold+=(${explode[61]})
	paramter_name+=(${explode[62]})
	paramter_notification_threshold+=(${explode[63]})
	paramter_name+=(${explode[64]})
	paramter_notification_threshold+=(${explode[65]})
	paramter_name+=(${explode[66]})
	paramter_notification_threshold+=(${explode[67]})
	paramter_name+=(${explode[68]})
	paramter_notification_threshold+=(${explode[69]})
	paramter_name+=(${explode[70]})
	paramter_notification_threshold+=(${explode[71]})
	paramter_name+=(${explode[72]})
	paramter_notification_threshold+=(${explode[73]})
	paramter_name+=(${explode[74]})
	paramter_notification_threshold+=(${explode[75]})
	paramter_name+=(${explode[76]})
	paramter_notification_threshold+=(${explode[77]})
	paramter_name+=(${explode[78]})
	paramter_notification_threshold+=(${explode[79]})

	if [ $script_enable -eq 1 ]
	then
		#confirm that the Synology SNMP settings were configured otherwise exit script
		if [ "$SNMP_user" = "" ];then
			echo "Synology NAS Username is BLANK, please configure the SNMP settings"
			SNMP_error_email
		else
			if [ "$AuthPass1" = "" ];then
				echo "Synology NAS Authentication Password is BLANK, please configure the SNMP settings"
				SNMP_error_email
			else
				if [ "$PrivPass2" = "" ];then
					echo "Synology NAS Privacy Password is BLANK, please configure the SNMP settings"
					SNMP_error_email
				else
					if [ $debug -eq 1 ];then
						echo "Synology SNTP settings are not Blank"
					fi
				fi
			fi
		fi
		
		# Getting NAS hostname from NAS, and capturing error output in the event we get an error during the SNMP_walk
		nas_name=$(snmpwalk -v3 -l authPriv -u $SNMP_user -a MD5 -A $AuthPass1 -x AES -X $PrivPass2 $nas_url:161 SNMPv2-MIB::sysName.0 -Ovqt 2>&1)

		#since $nas_name is the first time we have performed a SNMP request, let's make sure we did not receive any errors that could be caused by things like bad passwords, bad username, incorrect auth or privacy types etc
		#if we receive an error now, then something is wrong with the SNMP settings and this script will not be able to function so we should exit out of it. 
		#the five main error are
		#1 - too short of a password
			#Error: passphrase chosen is below the length requirements of the USM (min=8).
			#snmpwalk:  (The supplied password length is too short.)
			#Error generating a key (Ku) from the supplied privacy pass phrase.

		#2
			#Timeout: No Response from localhost:161

		#3
			#snmpwalk: Unknown user name

		#4
			#snmpwalk: Authentication failure (incorrect password, community or key)
			
		#5
			#we get nothing, the results are blank

		
		if [[ "$nas_name" == "Error:"* ]]; then #will search for the first error type
			echo "warning, the SNMP Auth password and or the Privacy password supplied is below the minimum 8 characters required. Exiting Script"
			SNMP_error_email
		fi
		
		if [[ "$nas_name" == "Timeout:"* ]]; then #will search for the second error type
			echo "The SNMP target did not respond. This could be the result of a bad SNMP privacy password, the wrong IP address, the wrong port, or SNMP services not being enabled on the target device"
			echo "Exiting Script"
			SNMP_error_email
		fi
		
		if [[ "$nas_name" == "snmpwalk: Unknown user name"* ]]; then #will search for the third error type
			echo "warning, The supplied username is incorrect. Exiting Script"
			SNMP_error_email
		fi
		
		if [[ "$nas_name" == "snmpwalk: Authentication failure (incorrect password, community or key)"* ]]; then #will search for the fourth error type
			echo "The Authentication protocol or password is incorrect. Exiting Script"
			SNMP_error_email
		fi
		
		if [[ "$nas_name" == "" ]]; then #will search for the fifth error type
			echo "Something is wrong with the SNMP settings, the results returned a blank/empty value. Exiting Script"
			SNMP_error_email
		fi
		
		if [[ "$nas_name" == "snmpwalk: Timeout" ]]; then #will search for the fifth error type
			echo "The SNMP target did not respond. This could be the result of a bad SNMP privacy password, the wrong IP address, the wrong port, or SNMP services not being enabled on the target device"
			echo "Exiting Script"
			SNMP_error_email
		fi
		
		if [ ! $capture_interval -eq 10 ]; then
			if [ ! $capture_interval -eq 15 ]; then
				if [ ! $capture_interval -eq 30 ]; then
					if [ ! $capture_interval -eq 60 ]; then
						echo "capture interval is not one of the allowable values of 10, 15, 30, or 60 seconds. Exiting the script"
						exit 1
					fi
				fi
			fi
		fi

		#loop the script. determine the number of times the script will execute per minute based on value of capture interval
		total_executions=$(( 60 / $capture_interval))
		
		echo "Capturing $total_executions times"
		i=0
		while [ $i -lt $total_executions ]; do
			
			#Create empty influxdb insert variable 
			post_url=
			
			measurement="synology_SMART_status2"
				
			disk_info=()	
			
			#get a list of every storage device installed in the NAS and store the data paths into an array
			while IFS= read -r line; do
				id=${line/"SYNOLOGY-STORAGEIO-MIB::storageIODevice."/}; id=${id%" = STRING:"*}
				disk_path=${line#*STRING: };
				disk_info+=([$id]=$disk_path)
			done < <(snmpwalk -v3 -l authPriv -u $SNMP_user -a MD5 -A $AuthPass1 -x AES -X $PrivPass2 $nas_url:161 SYNOLOGY-STORAGEIO-MIB::storageIODevice)
			
			#now that we have a list of all storage devices in the NAS, we need to gather all of the SMART data for each separate device
			#loop through each device one at a time
			for id in "${!disk_info[@]}"
			do
				
				disk_path="/dev/"${disk_info[$id]}
			
				#create empty array to hold all of the SMART index data returned from the SNMP walk command
				disk_SMART_index=() 
				
				#read in the SMART data from the NAS. this will process the incoming data line by line
				while IFS= read -r line; do
					smart_id=${line/"SYNOLOGY-SMART-MIB::diskSMARTInfoDevName."/}; smart_id=${smart_id%" = STRING: \"$disk_path\""} #these two instructions are filtering out the beginning of the text and then filtering out the end of the text. this leaves behind just the ID number Synology assigned the drive
					#the Synology SMART SNMP results will assign multiple ID numbers to each drive based on the number of SMART attributes the drive reports. since not all drives report the same number of attributes, this allows the results to be specific per device
					
					
					disk_SMART_index+=([$smart_id]=$disk_path) #save everything into an array. this array now contains all of the SMART ID numbers returned for the device we are currently scanning through
					
				done < <(snmpwalk -v3 -l authPriv -u $SNMP_user -a MD5 -A $AuthPass1 -x AES -X $PrivPass2 $nas_url:161 .1.3.6.1.4.1.6574.5.1.1.2 | grep -i "$disk_path")
				
				#now that we know which IDs are for the particular device we are working on, let's get all of the SMART details for each of those IDs
				ok_status_counter=0
				for id2 in "${!disk_SMART_index[@]}" 
				do
					
					if [[ ${disk_SMART_index[$id2]} == $disk_path ]]; then #only worry about stuff related to the current device
						while IFS= read -r line; do
							if [[ $line == "SYNOLOGY-SMART-MIB::diskSMARTAttrName.$id2 "* ]]; then
								disk_SMART_attribute_name=${line/"SYNOLOGY-SMART-MIB::diskSMARTAttrName."$id2" = STRING: "/};disk_SMART_attribute_name=${disk_SMART_attribute_name//\"}
							fi	
							if [[ $line == "SYNOLOGY-SMART-MIB::diskSMARTAttrId.$id2 "* ]]; then
								disk_SMART_attribute_ID=${line/"SYNOLOGY-SMART-MIB::diskSMARTAttrId."$id2" = INTEGER: "/};
							fi		
							if [[ $line == "SYNOLOGY-SMART-MIB::diskSMARTAttrCurrent.$id2 "* ]]; then
								disk_SMART_attribute_current=${line/"SYNOLOGY-SMART-MIB::diskSMARTAttrCurrent."$id2" = INTEGER: "/};
							fi		
							if [[ $line == "SYNOLOGY-SMART-MIB::diskSMARTAttrWorst.$id2 "* ]]; then
								disk_SMART_attribute_worst=${line/"SYNOLOGY-SMART-MIB::diskSMARTAttrWorst."$id2" = INTEGER: "/};
							fi	
							if [[ $line == "SYNOLOGY-SMART-MIB::diskSMARTAttrThreshold.$id2 "* ]]; then
								disk_SMART_attribute_threshold=${line/"SYNOLOGY-SMART-MIB::diskSMARTAttrThreshold."$id2" = INTEGER: "/};
							fi
							if [[ $line == "SYNOLOGY-SMART-MIB::diskSMARTAttrRaw64.$id2 "* ]]; then
								disk_SMART_attribute_raw=${line/"SYNOLOGY-SMART-MIB::diskSMARTAttrRaw64."$id2" = Counter64: "/};
							fi		
							if [[ $line == "SYNOLOGY-SMART-MIB::diskSMARTAttrStatus.$id2 "* ]]; then
								disk_SMART_attribute_status=${line/"SYNOLOGY-SMART-MIB::diskSMARTAttrStatus."$id2" = STRING: "/};
								if [[ $disk_SMART_attribute_status == "\"OK\"" ]]; then
									let ok_status_counter=ok_status_counter+1
								fi
							fi	
						done < <(snmpwalk -v3 -l authPriv -u $SNMP_user -a MD5 -A $AuthPass1 -x AES -X $PrivPass2 $nas_url:161 .1.3.6.1.4.1.6574.5 | grep -i "."$id2" =")
					else
						break
					fi
					
					#are email notifications enabled?
					if [[ $sendmail_installed == 1 ]]; then
						if [[ $enable_email_notifications == 1 ]]; then
							for attribute_counter in "${!paramter_name[@]}" 
							do
								if [[ $disk_SMART_attribute_name == ${paramter_name[$attribute_counter]} ]]; then
									if [[ ${paramter_type[$attribute_counter]} == ">" ]]; then
										if [ $disk_SMART_attribute_raw -gt ${paramter_notification_threshold[$attribute_counter]} ]; then
											send_mail $disk_SMART_attribute_name ${paramter_notification_threshold[$attribute_counter]} $disk_path $nas_name $disk_SMART_attribute_raw $email_contents $from_email_address $email_address "has exceeded"
										fi
									elif [[ ${paramter_type[$attribute_counter]} == "=" ]]; then
										if [ $disk_SMART_attribute_raw -eq ${paramter_notification_threshold[$attribute_counter]} ]; then
											send_mail $disk_SMART_attribute_name ${paramter_notification_threshold[$attribute_counter]} $disk_path $nas_name $disk_SMART_attribute_raw $email_contents $from_email_address $email_address "is equal to"
										fi
									elif [[ ${paramter_type[$attribute_counter]} == "<" ]]; then
										if [ $disk_SMART_attribute_raw -lt ${paramter_notification_threshold[$attribute_counter]} ]; then
											send_mail $disk_SMART_attribute_name ${paramter_notification_threshold[$attribute_counter]} $disk_path $nas_name $disk_SMART_attribute_raw $email_contents $from_email_address $email_address "is less than"
										fi
									fi
								fi
							done
						fi
					else
						echo "could not send notification email as MailPlus Server is unavailable"
					fi
					if [[ $debug == 1 ]]; then
						echo "SMART data for disk \"$disk_path\":"
						echo "$disk_SMART_attribute_name: ID: $disk_SMART_attribute_ID || Current Value: $disk_SMART_attribute_current || Worst Value: $disk_SMART_attribute_worst || Threshold: $disk_SMART_attribute_threshold || RAW Value: $disk_SMART_attribute_raw || Status: $disk_SMART_attribute_status" 
					fi
					post_url=$post_url"$measurement,nas_name=$nas_name,disk_path=$disk_path,smart_attribute=$disk_SMART_attribute_name ID=$disk_SMART_attribute_ID,current_value=$disk_SMART_attribute_current,worst_value=$disk_SMART_attribute_worst,threshold_value=$disk_SMART_attribute_threshold,RAW_value=$disk_SMART_attribute_raw,status=$disk_SMART_attribute_status
		"
				done
				if [[ $ok_status_counter == ${#disk_SMART_index[@]} ]]; then
					disk_status=1
				else
					disk_status=0
					echo "$Warning $disk_path overall SMART status is not \"OK\", sending email"
					
					if [ $sendmail_installed -eq 1 ]; then	
						now=$(date +"%T")
						mailbody="$now - Warning SMART on disk $disk_path on $nas_name is no longer reporting \"OK\" Status, check the SMART logs to determine the issue"
						echo "from: $from_email_address " > $email_contents
						echo "to: $email_address " >> $email_contents
						echo "subject: $disk_path SMART ALERT for $nas_name " >> $email_contents
						echo "" >> $email_contents
						echo $mailbody >> $email_contents
						email_response=$(sendmail -t < $email_contents  2>&1)
						if [[ "$email_response" == "" ]]; then
							echo -e "\nEmail Sent Successfully indicating overall SMART status is not \"OK\"" |& tee -a $email_contents
						else
							echo -e "\n\nWARNING -- An error occurred while sending email. The error was: $email_response\n\n" |& tee $email_contents
						fi	
					
					else
						echo -e "\n\nERROR -- Could not send alert email that overall SMART status is not \"OK\" -- command \"sendmail\" is not available\n\n"
					fi

				fi
				post_url=$post_url"$measurement,nas_name=$nas_name,disk_path=$disk_path disk_status=$disk_status
		"
			done
		
			#get NVME drive details. as this is not available from SNMP, we will pull it using the nvme command. 
			nvme_number_installed=$(nvme list | wc -l)
			nvme_number_installed=$(( ( $nvme_number_installed - 2 ) / 2 )) #remove the first two lines as they are just table header information, and two entries are listed per drive
			if [[ $debug == 1 ]]; then
				echo "nvme_number_installed is $nvme_number_installed"
			fi

			if [[ $nvme_number_installed < 1 ]]; then
				echo "no NVME drives installed, skipping NVME capture"
			else
				for (( c=0; c<$nvme_number_installed; c++ ))
				do 
					post_url=$post_url"$measurement,nas_name=$nas_name,disk_path=/dev/nvme${c}n1 "
					line_num=0
					while IFS= read -r line; do
										
						if [[ $line_num != 0 ]]; then
							disk_SMART_attribute_name=$(echo ${line%:*} | xargs)
							
							secondString="_"
							disk_SMART_attribute_name=${disk_SMART_attribute_name//\ /$secondString} #replace all white space with underscore
							
							
							disk_SMART_attribute_raw=$(echo ${line##*:} | xargs)
					
							#cleanup the data to make all returned values numerical numbers and not strings
							secondString=""
							disk_SMART_attribute_raw=${disk_SMART_attribute_raw//\ /$secondString} #remove all white space
							disk_SMART_attribute_raw=${disk_SMART_attribute_raw//\,/$secondString} #remove the commas from numerical values so it is just a plain number and not a string
							disk_SMART_attribute_raw=${disk_SMART_attribute_raw//\%/$secondString} #remove the % symbol from items containing it so it is just a plain number and not a string
							disk_SMART_attribute_raw=${disk_SMART_attribute_raw//\C/$secondString} #remove the "C" from temperature values so it is just a plain number and not a string
					
							post_url=$post_url"$disk_SMART_attribute_name=$disk_SMART_attribute_raw,"
							
							
							#are email notifications enabled?
							if [[ $sendmail_installed == 1 ]]; then
								if [[ $enable_email_notifications == 1 ]]; then
									for attribute_counter in "${!paramter_name[@]}" 
									do
										if [[ $disk_SMART_attribute_name == ${paramter_name[$attribute_counter]} ]]; then
											if [[ ${paramter_type[$attribute_counter]} == ">" ]]; then
												if [ $disk_SMART_attribute_raw -gt ${paramter_notification_threshold[$attribute_counter]} ]; then
													send_mail $disk_SMART_attribute_name ${paramter_notification_threshold[$attribute_counter]} "/dev/nvme${c}n1" $nas_name $disk_SMART_attribute_raw $email_contents $from_email_address $email_address "has exceeded"
													#echo "$disk_SMART_attribute_name on \"/dev/nvme${c}n1\" is greater than ${paramter_notification_threshold[$attribute_counter]}, it is reporting $disk_SMART_attribute_raw"
												fi
											elif [[ ${paramter_type[$attribute_counter]} == "=" ]]; then
												if [ $disk_SMART_attribute_raw -eq ${paramter_notification_threshold[$attribute_counter]} ]; then
													send_mail $disk_SMART_attribute_name ${paramter_notification_threshold[$attribute_counter]} "/dev/nvme${c}n1" $nas_name $disk_SMART_attribute_raw $email_contents $from_email_address $email_address "is equal to"
													#echo "$disk_SMART_attribute_name on \"/dev/nvme${c}n1\" is equal to ${paramter_notification_threshold[$attribute_counter]}, it is reporting $disk_SMART_attribute_raw"
												fi
											elif [[ ${paramter_type[$attribute_counter]} == "<" ]]; then
												if [ $disk_SMART_attribute_raw -lt ${paramter_notification_threshold[$attribute_counter]} ]; then
													send_mail $disk_SMART_attribute_name ${paramter_notification_threshold[$attribute_counter]} "/dev/nvme${c}n1" $nas_name $disk_SMART_attribute_raw $email_contents $from_email_address $email_address "is less than"
													#echo "$disk_SMART_attribute_name on \"/dev/nvme${c}n1\" is less than ${paramter_notification_threshold[$attribute_counter]}, it is reporting $disk_SMART_attribute_raw"
												fi
											fi
										fi
									done
								fi
							else
								echo "could not send notification email as MailPlus Server is unavailable"
							fi
						fi
						
						let line_num=line_num+1
					done < <(nvme smart-log /dev/nvme${c}n1)
					
					let line_num=line_num-1
					post_url=$post_url"num_paramters=$line_num

"
				done
			fi
   
			#Post to influxdb
			if [[ $influx_db_version == 1 ]]; then
				echo "saving using influx version 1"
				curl -i -XPOST "http://$influxdb_host:$influxdb_port/write?u=$influxdb_user&p=$influxdb_pass&db=$influxdb_name" --data-binary "$post_url"
			else
				curl -XPOST "http://$influxdb_host:$influxdb_port/api/v2/write?bucket=$influxdb_name&org=$influxdb_org" -H "Authorization: Token $influxdb_pass" --data-raw "$post_url"
			fi
			
			if [[ $debug == 1 ]]; then
				echo "$post_url"
			fi
		
			let i=i+1
		
			echo "Capture #$i complete"
		
			#Sleeping for capture interval unless its last capture then we don't sleep
			if (( $i < $total_executions)); then
				sleep $(( $capture_interval -1))
			fi
		done
	else
		echo "script is disabled"
	fi
else
	now=$(date +"%T")
	echo "Configuration file for script \"${0##*/}\" is missing, skipping script and will send alert email every 60 minuets"
	#send an email indicating script config file is missing and script will not run
	mailbody="$now - Warning SMART SNMP Monitoring Failed for script \"${0##*/}\" - Configuration file is missing "
	echo "from: $from_email_address " > $email_contents
	echo "to: $email_address " >> $email_contents
	echo "subject: Warning SMART SNMP Monitoring Failed for script \"${0##*/}\" - Configuration file is missing " >> $email_contents
	echo "" >> $email_contents
	echo $mailbody >> $email_contents
		
	if [[ "$email_address" == "" || "$from_email_address" == "" ]];then
		echo -e "\n\nNo email address information is configured, Cannot send an email indicating script \"${0##*/}\" config file is missing and script will not run"
	else
		if [ $sendmail_installed -eq 1 ]; then
			email_response=$(sendmail -t < $email_contents  2>&1)
			if [[ "$email_response" == "" ]]; then
				echo -e "\nEmail Sent Successfully indicating script \"${0##*/}\" config file is missing and script will not run" |& tee -a $email_contents
			else
				echo -e "\n\nWARNING -- An error occurred while sending email. The error was: $email_response\n\n" |& tee $email_contents
			fi	
		else
			echo "Unable to send email, \"sendmail\" command is unavailable"
		fi
	fi
	exit 1
fi
