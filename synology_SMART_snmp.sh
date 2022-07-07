#!/bin/bash
#version 4.0 dated 7/7/2022
#By Brian Wallace

#This script pulls various information from the Synology NAS
#add this script to a scheduled task within synology's task scheduler

#suggest to install the script in synology's web directory on volume1 at /volume1/web/logging/
#if a different directory is desired, change these variables accordingly
config_file_location="/volume1/web/config/config_files/config_files_local"
config_file_name="smart_logging_config.txt"
debug=0



#for my personal use as i have multiple synology systems, these lines can be deleted by other users
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
if ! mkdir $config_file_location/synology_smart_snmp.lock; then
	echo "Failed to acquire lock.\n" >&2
	exit 1
fi
trap 'rm -rf $config_file_location/synology_smart_snmp.lock' EXIT #remove the lockdir on exit


########################################
#Send Email Notification Function
########################################
# send_mail $disk_SMART_attribute_name $paramter_1_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "has exceeded"
send_mail(){
	# ${1} = $disk_SMART_attribute_name
	# ${2} = $paramter_1_notification_threshold
	# ${3} = $disk_path
	# ${4} = $nas_name
	# ${5} = $disk_SMART_attribute_raw
	# ${6} = $notification_text_file   ($config_file_location/email_notification.txt)
	# ${7} = $from_email_address
	# ${8} = $email_address
	# ${9} = $comparison

	echo "${1} ${9} its threshold value of ${2} on disk ${3}. It currently is reporting a value of ${5}. Sending Alert Email"
	local mailbody="Warning SMART Attribute ${1} on disk ${3} on ${4} ${9} the threshold value of ${2}. It currently is reporting a value of ${5}"
	echo "from: ${7} " > ${6}
	echo "to: ${8} " >> ${6}
	echo "subject: ${3} SMART ALERT for ${4} " >> ${6}
	echo "" >> ${6}
	echo $mailbody >> ${6}
	cat ${6} | sendmail -t

}

if [ -r $config_file_location/$config_file_name ]; then
	#file is available and readable 
	
	#read in file
	input_read=$(<$config_file_location/$config_file_name)
	#explode the configuration into an array with the colon as the delimiter
	explode=(`echo $input_read | sed 's/,/\n/g'`)
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
	paramter_1_name=${explode[17]}
	paramter_1_notification_threshold=${explode[18]}
	paramter_2_name=${explode[19]}
	paramter_2_notification_threshold=${explode[20]}
	paramter_3_name=${explode[21]}
	paramter_3_notification_threshold=${explode[22]}
	paramter_4_name=${explode[23]}
	paramter_4_notification_threshold=${explode[24]}
	paramter_5_name=${explode[25]}
	paramter_5_notification_threshold=${explode[26]}
	from_email_address=${explode[27]}
	snmp_auth_protocol=${explode[28]}
	snmp_privacy_protocol=${explode[29]}
	paramter_1_type=${explode[30]}
	paramter_2_type=${explode[31]}
	paramter_3_type=${explode[32]}
	paramter_4_type=${explode[33]}
	paramter_5_type=${explode[34]}
	paramter_6_type=${explode[35]}
	paramter_7_type=${explode[36]}
	paramter_8_type=${explode[37]}
	paramter_9_type=${explode[38]}
	paramter_10_type=${explode[39]}
	paramter_11_type=${explode[40]}
	paramter_12_type=${explode[41]}
	paramter_13_type=${explode[42]}
	paramter_14_type=${explode[43]}
	paramter_15_type=${explode[44]}
	paramter_16_type=${explode[45]}
	paramter_17_type=${explode[46]}
	paramter_18_type=${explode[47]}
	paramter_19_type=${explode[48]}
	paramter_20_type=${explode[49]}
	paramter_6_name=${explode[50]}
	paramter_6_notification_threshold=${explode[51]}
	paramter_7_name=${explode[52]}
	paramter_7_notification_threshold=${explode[53]}
	paramter_8_name=${explode[54]}
	paramter_8_notification_threshold=${explode[55]}
	paramter_9_name=${explode[56]}
	paramter_9_notification_threshold=${explode[57]}
	paramter_10_name=${explode[58]}
	paramter_10_notification_threshold=${explode[59]}
	paramter_11_name=${explode[60]}
	paramter_11_notification_threshold=${explode[61]}
	paramter_12_name=${explode[62]}
	paramter_12_notification_threshold=${explode[63]}
	paramter_13_name=${explode[64]}
	paramter_13_notification_threshold=${explode[65]}
	paramter_14_name=${explode[66]}
	paramter_14_notification_threshold=${explode[67]}
	paramter_15_name=${explode[68]}
	paramter_15_notification_threshold=${explode[69]}
	paramter_16_name=${explode[70]}
	paramter_16_notification_threshold=${explode[71]}
	paramter_17_name=${explode[72]}
	paramter_17_notification_threshold=${explode[73]}
	paramter_18_name=${explode[74]}
	paramter_18_notification_threshold=${explode[75]}
	paramter_19_name=${explode[76]}
	paramter_19_notification_threshold=${explode[77]}
	paramter_20_name=${explode[78]}
	paramter_20_notification_threshold=${explode[79]}

	if [ $script_enable -eq 1 ]
	then
		#confirm that the synology SNMP settings were configured otherwise exit script
		if [ "$SNMP_user" = "" ];then
			echo "Synology NAS Username is BLANK, please configure the SNMP settings"
			exit
		else
			if [ "$AuthPass1" = "" ];then
				echo "Synology NAS Authentication Password is BLANK, please configure the SNMP settings"
				exit
			else
				if [ "$PrivPass2" = "" ];then
					echo "Synology NAS Privacy Password is BLANK, please configure the SNMP settings"
					exit
				else
					if [ $debug -eq 1 ];then
						echo "Synology SNTP settings are not Blank"
					fi
				fi
			fi
		fi
	
		#verify MailPlus Server package is installed and running as the "sendmail" command is not installed in synology by default. the MailPlus Server package is required
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
		
		
		# Getting NAS hostname from NAS if it was not manually set in the configuration settings
			nas_name=`snmpwalk -v3 -l authPriv -u $SNMP_user -a MD5 -A $AuthPass1 -x AES -X $PrivPass2 $nas_url:161 SNMPv2-MIB::sysName.0 -Ovqt`

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
					
					if [[ $line == *$disk_path\" ]]; then	#searching the latest received line of data for the sub-string of the current disk's data path 
						smart_id=${line/"SYNOLOGY-SMART-MIB::diskSMARTInfoDevName."/}; smart_id=${smart_id%" = STRING: \"$disk_path\""} #these two instructions are filtering out the beginning of the text and then filtering out the end of the text. this leaves behind just the ID number synology assigned the drive
						#the synology SMART SNMP results will assign multiple ID numbers to each drive based on the number of SMART attributes the drive reports. since not all drives report the same number of attributes, this allows the results to be specific per device
						disk_SMART_index+=([$smart_id]=$disk_path) #save everything into an array. this array now contains all of the SMART ID numbers returned for the device we are currently scanning through
					fi
					
				done < <(snmpwalk -v3 -l authPriv -u $SNMP_user -a MD5 -A $AuthPass1 -x AES -X $PrivPass2 $nas_url:161 .1.3.6.1.4.1.6574.5)
				
				#now that we know which IDs are for the particular device we are working on, let's get all of the SMART details for each of those IDs
				#echo "SMART data for disk \"$disk_path\":"
				ok_status_counter=0
				for id2 in "${!disk_SMART_index[@]}" 
				do
					if [[ ${disk_SMART_index[$id2]} == $disk_path ]]; then #only worry about stuff related to the current device
					#echo "capturing index $id2"
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
							if [[ $line == "SYNOLOGY-SMART-MIB::diskSMARTAttrRaw.$id2 "* ]]; then
								disk_SMART_attribute_raw=${line/"SYNOLOGY-SMART-MIB::diskSMARTAttrRaw."$id2" = INTEGER: "/};
							fi	
							if [[ $line == "SYNOLOGY-SMART-MIB::diskSMARTAttrStatus.$id2 "* ]]; then
								disk_SMART_attribute_status=${line/"SYNOLOGY-SMART-MIB::diskSMARTAttrStatus."$id2" = STRING: "/};
								if [[ $disk_SMART_attribute_status == "\"OK\"" ]]; then
									let ok_status_counter=ok_status_counter+1
								fi
							fi	
						done < <(snmpwalk -v3 -l authPriv -u $SNMP_user -a MD5 -A $AuthPass1 -x AES -X $PrivPass2 $nas_url:161 .1.3.6.1.4.1.6574.5)
					else
						break
					fi
					
					#are email notifications enabled?
					if [[ $sendmail_installed == 1 ]]; then
						if [[ $enable_email_notifications == 1 ]]; then
							if [[ $disk_SMART_attribute_name == $paramter_1_name ]]; then
								if [[ $paramter_1_type == ">" ]]; then
									if [ $disk_SMART_attribute_raw -gt $paramter_1_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_1_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "has exceeded"
									fi
								elif [[ $paramter_1_type == "=" ]]; then
									if [ $disk_SMART_attribute_raw -eq $paramter_1_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_1_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "is equal to"
									fi
								elif [[ $paramter_1_type == "<" ]]; then
									if [ $disk_SMART_attribute_raw -lt $paramter_1_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_1_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "is less than"
									fi
								fi
							fi
							
							if [[ $disk_SMART_attribute_name == $paramter_2_name ]]; then
								if [[ $paramter_2_type == ">" ]]; then
									if [ $disk_SMART_attribute_raw -gt $paramter_2_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_2_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "has exceeded"
									fi
								elif [[ $paramter_2_type == "=" ]]; then
									if [ $disk_SMART_attribute_raw -eq $paramter_2_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_2_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "is equal to"
									fi
								elif [[ $paramter_2_type == "<" ]]; then
									if [ $disk_SMART_attribute_raw -lt $paramter_2_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_2_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "is less than"
									fi
								fi
							fi
							
							if [[ $disk_SMART_attribute_name == $paramter_3_name ]]; then
								if [[ $paramter_3_type == ">" ]]; then
									if [ $disk_SMART_attribute_raw -gt $paramter_3_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_3_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "has exceeded"
									fi
								elif [[ $paramter_3_type == "=" ]]; then
									if [ $disk_SMART_attribute_raw -eq $paramter_3_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_3_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "is equal to"
									fi
								elif [[ $paramter_3_type == "<" ]]; then
									if [ $disk_SMART_attribute_raw -lt $paramter_3_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_3_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "is less than"
									fi
								fi
							fi
							
							if [[ $disk_SMART_attribute_name == $paramter_4_name ]]; then
								if [[ $paramter_4_type == ">" ]]; then
									if [ $disk_SMART_attribute_raw -gt $paramter_4_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_4_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "has exceeded"
									fi
								elif [[ $paramter_4_type == "=" ]]; then
									if [ $disk_SMART_attribute_raw -eq $paramter_4_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_4_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "is equal to"
									fi
								elif [[ $paramter_4_type == "<" ]]; then
									if [ $disk_SMART_attribute_raw -lt $paramter_4_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_4_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "is less than"
									fi
								fi
							fi
							
							if [[ $disk_SMART_attribute_name == $paramter_5_name ]]; then
								if [[ $paramter_5_type == ">" ]]; then
									if [ $disk_SMART_attribute_raw -gt $paramter_5_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_5_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "has exceeded"
									fi
								elif [[ $paramter_5_type == "=" ]]; then
									if [ $disk_SMART_attribute_raw -eq $paramter_5_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_5_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "is equal to"
									fi
								elif [[ $paramter_5_type == "<" ]]; then
									if [ $disk_SMART_attribute_raw -lt $paramter_5_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_5_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "is less than"
									fi
								fi
							fi
							
							if [[ $disk_SMART_attribute_name == $paramter_6_name ]]; then
								if [[ $paramter_6_type == ">" ]]; then
									if [ $disk_SMART_attribute_raw -gt $paramter_6_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_6_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "has exceeded"
									fi
								elif [[ $paramter_6_type == "=" ]]; then
									if [ $disk_SMART_attribute_raw -eq $paramter_6_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_6_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "is equal to"
									fi
								elif [[ $paramter_6_type == "<" ]]; then
									if [ $disk_SMART_attribute_raw -lt $paramter_6_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_6_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "is less than"
									fi
								fi
							fi
							
							if [[ $disk_SMART_attribute_name == $paramter_7_name ]]; then
								if [[ $paramter_7_type == ">" ]]; then
									if [ $disk_SMART_attribute_raw -gt $paramter_7_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_7_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "has exceeded"
									fi
								elif [[ $paramter_7_type == "=" ]]; then
									if [ $disk_SMART_attribute_raw -eq $paramter_7_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_7_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "is equal to"
									fi
								elif [[ $paramter_7_type == "<" ]]; then
									if [ $disk_SMART_attribute_raw -lt $paramter_7_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_7_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "is less than"
									fi
								fi
							fi
							
							if [[ $disk_SMART_attribute_name == $paramter_8_name ]]; then
								if [[ $paramter_8_type == ">" ]]; then
									if [ $disk_SMART_attribute_raw -gt $paramter_8_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_8_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "has exceeded"
									fi
								elif [[ $paramter_8_type == "=" ]]; then
									if [ $disk_SMART_attribute_raw -eq $paramter_8_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_8_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "is equal to"
									fi
								elif [[ $paramter_8_type == "<" ]]; then
									if [ $disk_SMART_attribute_raw -lt $paramter_8_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_8_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "is less than"
									fi
								fi
							fi
							
							if [[ $disk_SMART_attribute_name == $paramter_9_name ]]; then
								if [[ $paramter_9_type == ">" ]]; then
									if [ $disk_SMART_attribute_raw -gt $paramter_9_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_9_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "has exceeded"
									fi
								elif [[ $paramter_9_type == "=" ]]; then
									if [ $disk_SMART_attribute_raw -eq $paramter_9_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_9_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "is equal to"
									fi
								elif [[ $paramter_9_type == "<" ]]; then
									if [ $disk_SMART_attribute_raw -lt $paramter_9_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_9_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "is less than"
									fi
								fi
							fi
							
							if [[ $disk_SMART_attribute_name == $paramter_10_name ]]; then
								if [[ $paramter_10_type == ">" ]]; then
									if [ $disk_SMART_attribute_raw -gt $paramter_10_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_10_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "has exceeded"
									fi
								elif [[ $paramter_10_type == "=" ]]; then
									if [ $disk_SMART_attribute_raw -eq $paramter_10_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_10_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "is equal to"
									fi
								elif [[ $paramter_10_type == "<" ]]; then
									if [ $disk_SMART_attribute_raw -lt $paramter_10_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_10_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "is less than"
									fi
								fi
							fi
							
							if [[ $disk_SMART_attribute_name == $paramter_11_name ]]; then
								if [[ $paramter_11_type == ">" ]]; then
									if [ $disk_SMART_attribute_raw -gt $paramter_11_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_11_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "has exceeded"
									fi
								elif [[ $paramter_11_type == "=" ]]; then
									if [ $disk_SMART_attribute_raw -eq $paramter_11_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_11_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "is equal to"
									fi
								elif [[ $paramter_11_type == "<" ]]; then
									if [ $disk_SMART_attribute_raw -lt $paramter_11_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_11_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "is less than"
									fi
								fi
							fi
							
							if [[ $disk_SMART_attribute_name == $paramter_12_name ]]; then
								if [[ $paramter_12_type == ">" ]]; then
									if [ $disk_SMART_attribute_raw -gt $paramter_12_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_12_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "has exceeded"
									fi
								elif [[ $paramter_12_type == "=" ]]; then
									if [ $disk_SMART_attribute_raw -eq $paramter_12_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_12_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "is equal to"
									fi
								elif [[ $paramter_12_type == "<" ]]; then
									if [ $disk_SMART_attribute_raw -lt $paramter_12_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_12_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "is less than"
									fi
								fi
							fi
							
							if [[ $disk_SMART_attribute_name == $paramter_13_name ]]; then
								if [[ $paramter_13_type == ">" ]]; then
									if [ $disk_SMART_attribute_raw -gt $paramter_13_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_13_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "has exceeded"
									fi
								elif [[ $paramter_13_type == "=" ]]; then
									if [ $disk_SMART_attribute_raw -eq $paramter_13_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_13_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "is equal to"
									fi
								elif [[ $paramter_13_type == "<" ]]; then
									if [ $disk_SMART_attribute_raw -lt $paramter_13_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_13_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "is less than"
									fi
								fi
							fi
							
							if [[ $disk_SMART_attribute_name == $paramter_14_name ]]; then
								if [[ $paramter_14_type == ">" ]]; then
									if [ $disk_SMART_attribute_raw -gt $paramter_14_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_14_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "has exceeded"
									fi
								elif [[ $paramter_14_type == "=" ]]; then
									if [ $disk_SMART_attribute_raw -eq $paramter_14_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_14_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "is equal to"
									fi
								elif [[ $paramter_14_type == "<" ]]; then
									if [ $disk_SMART_attribute_raw -lt $paramter_14_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_14_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "is less than"
									fi
								fi
							fi
							
							if [[ $disk_SMART_attribute_name == $paramter_15_name ]]; then
								if [[ $paramter_15_type == ">" ]]; then
									if [ $disk_SMART_attribute_raw -gt $paramter_15_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_15_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "has exceeded"
									fi
								elif [[ $paramter_15_type == "=" ]]; then
									if [ $disk_SMART_attribute_raw -eq $paramter_15_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_15_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "is equal to"
									fi
								elif [[ $paramter_15_type == "<" ]]; then
									if [ $disk_SMART_attribute_raw -lt $paramter_15_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_15_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "is less than"
									fi
								fi
							fi
							
							if [[ $disk_SMART_attribute_name == $paramter_16_name ]]; then
								if [[ $paramter_16_type == ">" ]]; then
									if [ $disk_SMART_attribute_raw -gt $paramter_16_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_16_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "has exceeded"
									fi
								elif [[ $paramter_16_type == "=" ]]; then
									if [ $disk_SMART_attribute_raw -eq $paramter_16_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_16_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "is equal to"
									fi
								elif [[ $paramter_16_type == "<" ]]; then
									if [ $disk_SMART_attribute_raw -lt $paramter_16_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_16_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "is less than"
									fi
								fi
							fi
							
							if [[ $disk_SMART_attribute_name == $paramter_17_name ]]; then
								if [[ $paramter_17_type == ">" ]]; then
									if [ $disk_SMART_attribute_raw -gt $paramter_17_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_17_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "has exceeded"
									fi
								elif [[ $paramter_17_type == "=" ]]; then
									if [ $disk_SMART_attribute_raw -eq $paramter_17_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_17_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "is equal to"
									fi
								elif [[ $paramter_17_type == "<" ]]; then
									if [ $disk_SMART_attribute_raw -lt $paramter_17_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_17_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "is less than"
									fi
								fi
							fi
							
							if [[ $disk_SMART_attribute_name == $paramter_18_name ]]; then
								if [[ $paramter_18_type == ">" ]]; then
									if [ $disk_SMART_attribute_raw -gt $paramter_18_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_18_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "has exceeded"
									fi
								elif [[ $paramter_18_type == "=" ]]; then
									if [ $disk_SMART_attribute_raw -eq $paramter_18_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_18_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "is equal to"
									fi
								elif [[ $paramter_18_type == "<" ]]; then
									if [ $disk_SMART_attribute_raw -lt $paramter_18_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_18_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "is less than"
									fi
								fi
							fi
							
							if [[ $disk_SMART_attribute_name == $paramter_19_name ]]; then
								if [[ $paramter_19_type == ">" ]]; then
									if [ $disk_SMART_attribute_raw -gt $paramter_19_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_19_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "has exceeded"
									fi
								elif [[ $paramter_19_type == "=" ]]; then
									if [ $disk_SMART_attribute_raw -eq $paramter_19_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_19_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "is equal to"
									fi
								elif [[ $paramter_19_type == "<" ]]; then
									if [ $disk_SMART_attribute_raw -lt $paramter_19_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_19_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "is less than"
									fi
								fi
							fi
							
							if [[ $disk_SMART_attribute_name == $paramter_20_name ]]; then
								if [[ $paramter_20_type == ">" ]]; then
									if [ $disk_SMART_attribute_raw -gt $paramter_20_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_20_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "has exceeded"
									fi
								elif [[ $paramter_20_type == "=" ]]; then
									if [ $disk_SMART_attribute_raw -eq $paramter_20_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_20_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "is equal to"
									fi
								elif [[ $paramter_20_type == "<" ]]; then
									if [ $disk_SMART_attribute_raw -lt $paramter_20_notification_threshold ]; then
										send_mail $disk_SMART_attribute_name $paramter_20_notification_threshold $disk_path $nas_name $disk_SMART_attribute_raw $config_file_location/email_notification.txt $from_email_address $email_address "is less than"
									fi
								fi
							fi
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
					mailbody="Warning SMART on disk $disk_path on $nas_name is no longer reporting \"OK\" Status"
					echo "from: $from_email_address " > $config_file_location/email_notification.txt
					echo "to: $email_address " >> $config_file_location/email_notification.txt
					echo "subject: $disk_path SMART ALERT for $nas_name " >> $config_file_location/email_notification.txt
					echo "" >> $config_file_location/email_notification.txt
					echo $mailbody >> $config_file_location/email_notification.txt
					cat $config_file_location/email_notification.txt | sendmail -t
				fi
				post_url=$post_url"$measurement,nas_name=$nas_name,disk_path=$disk_path disk_status=$disk_status
		"
			done
		
		
			#Post to influxdb
			if [[ $influx_db_version == 1 ]]; then
				#if using influxdb version 1.x.x
				echo "saving using influx version 1"
				curl -i -XPOST "http://$influxdb_host:$influxdb_port/write?u=$influxdb_user&p=$influxdb_pass&db=$influxdb_name" --data-binary "$post_url"
			else
				#if using influxdb version 2.x.x
				echo "saving using influx version 2"
				#echo "-XPOST \"http://$influxdb_host:$influxdb_port/api/v2/write?bucket=$influxdb_name&org=$influxdb_org\" -H \"Authorization: Token $influxdb_pass\" --data-raw \"post_url\""
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
	echo "Configuration file is missing"
fi
