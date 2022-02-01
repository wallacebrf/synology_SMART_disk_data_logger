#!/bin/bash
#version 2.0 dated 2/1/2022
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


#check if config_file_location directory exists
if [ ! -d $config_file_location ] ; then
	#directory does not exist, let's create it
	echo "directory $config_file_location did not exist, directory will now be created"
	mkdir -p $config_file_location
fi

#check to see if configuration file exists
if [ ! -r $config_file_location/$config_file_name ]; then
	#file is missing, let's create it and store default values into it. after it is created, the script will exit the first run and the configuration file can be edited as required. 
	#NOTE: when editing the file, ensure the parameter value remains within the quotes
	echo "
	SNMP_user:\"username\"
	capture_interval:\"60\"
	nas_url:\"localhost\"
	nas_name:\"\"
	ups_group:\"NAS\"
	influxdb_host:\"localhost\"
	influxdb_port:\"8086\"
	influxdb_name:\"db_name\"
	influxdb_user:\"db_user\"
	influxdb_pass:\"db_password\"
	script_enable:\"1\"
	AuthPass1:\"SNMP_auth_passord\"
	PrivPass2:\"SNMP_privacy_passord\"
	influx_db_version:\"2\"
	influxdb_org:\"org\"
	enable_email_notifications:\"0\"
	email_address:\"admin@domain.com\"
	paramter_1_name:\"Reallocated_Sector_Ct\"
	paramter_1_notification_threshold:\"1\"
	paramter_2_name:\"Seek_Error_Rate\"
	paramter_2_notification_threshold:\"1\"
	paramter_3_name:\"Temperature_Celsius\"
	paramter_3_notification_threshold:\"1\"
	paramter_4_name:\"Spin_Retry_Count\"
	paramter_4_notification_threshold:\"1\"
	paramter_5_name:\"UDMA_CRC_Error_Count\"
	paramter_5_notification_threshold:\"1\"
	" |& tee $config_file_location/$config_file_name
	#check to make sure it was created correctly
	
	if [ ! -r $config_file_location/$config_file_name ]; then
		echo "configuration file creation failed"
		exit
	else
		echo "configuration file successfully created, exiting script. Please configure settings as required before running the script again"
		exit
	fi
fi

#create a lock file in the configuration directory to prevent more than one instance of this script from executing  at once
if ! mkdir $config_file_location/synology_smart_snmp.lock; then
	echo "Failed to acquire lock.\n" >&2
	exit 1
fi
trap 'rm -rf $config_file_location/synology_smart_snmp.lock' EXIT #remove the lockdir on exit

#reading in variables from configuration file
	#SNMP_user									#what user name is used for the SNMP version 3.0 config
	#capture_interval							#[seconds] how often is the script going to collect data? suggested is 60 so script collects data once when executed. 
	#nas_url	  								#IP of the synology NAS the script will gather SMART data from using SNMP
	#nas_name									#name of the synology NAS. if this is not set, the script will gather the name from the NAS itself	
	#ups_group									#currently unused
	#influxdb_host								#IP of the influxDB destination server
	#influxdb_port								#port of Influxdb
	#influxdb_name								#name of the influxdb database. Note: if using influxdb version 1.x.x this will be something like "SMART_DATA" but if using influxdb 2.x.x this will be the randomly generated string of characters influxdb generates for each data bucket identification.		
	#influxdb_user								#user name to log into influxdb. Note: this is only needed for influxdb version 1.x.x
	#influxdb_pass								#password to log into influxdb. Note: if using influxdb version 1.x.x this will be something like "my_passord" but if using influxdb 2.x.x this will be the API key / "Token" that must be generated within influxdb 2.x.x
	#script_enable								#is the script enabled or disabled? 1=enabled, 0=disabled. 
	#AuthPass1									#SNMP Authorization password. NOTE: this script is configured to use SNMP version 3 using MD5 for authorization and AES for privacy. ensure the synology NAS is configured accordingly
	#PrivPass2									#SNMP privacy password. NOTE: this script is configured to use SNMP version 3 using MD5 for authorization and AES for privacy. ensure the synology NAS is configured accordingly
	#influx_db_version							#set to a value of 1 if using influxdb earlier than version 2.0. set to a value of 2 if using influxdb version 2.0 or higher. 
	#influxdb_org								#only needed for influxdb version 2.0 and higher
	#enable_email_notifications					#enable the ability of this script to send emails alerting if things are past certain set points. NOTE: this ability requires synology "Synology MailPlus Server" installed on the system and properly configured. NOTE 2: if multiple drives report data that meets the set point values, separate emails will be sent per drive
	#email_address								#what email address should the alerts be sent to?
	
	#note: due to different drives reporting different SMART details, this script allows for notifications of five different parameters if they exceed a desired set point. 
	#	   the different paramter_x_name variables must be set to the name of the desired parameter as reported by the system
	#      the different paramter_x_notification_threshold values can be configured as desired to receive a notification. NOTE: until the issue is corrected, or the threshold value is changed, an email will be sent each time this script executes
	
	#paramter_1_name							#name of first parameter to monitor. this must be exactly as reported by the system for example "Seek_Error_Rate" must include the underscores
	#paramter_1_notification_threshold			#value where the notification will be sent
	#paramter_2_name
	#paramter_2_notification_threshold
	#paramter_3_name
	#paramter_3_notification_threshold
	#paramter_4_name
	#paramter_4_notification_threshold
	#paramter_5_name
	#paramter_5_notification_threshold
	
if [ -r $config_file_location/$config_file_name ]; then
	#file is available and readable 
	
	#read in file
	input_read=$(<$config_file_location/$config_file_name)
	#explode the configuration into an array with the colon as the delimiter
	explode=(`echo $input_read | sed 's/:/\n/g'`)
	#save the parameter values into the respective variable and remove the quotes
	SNMP_user=${explode[1]//\"}
	capture_interval=${explode[3]//\"}
	nas_url=${explode[5]//\"}
	nas_name=${explode[7]//\"}
	ups_group=${explode[9]//\"}
	influxdb_host=${explode[11]//\"}
	influxdb_port=${explode[13]//\"}
	influxdb_name=${explode[15]//\"}
	influxdb_user=${explode[17]//\"}
	influxdb_pass=${explode[19]//\"}
	script_enable=${explode[21]//\"}
	AuthPass1=${explode[23]//\"}
	PrivPass2=${explode[25]//\"}
	influx_db_version=${explode[27]//\"}
	influxdb_org=${explode[29]//\"}
	enable_email_notifications=${explode[31]//\"}
	email_address=${explode[33]//\"}
	paramter_1_name=${explode[35]//\"}
	paramter_1_notification_threshold=${explode[37]//\"}
	paramter_2_name=${explode[39]//\"}
	paramter_2_notification_threshold=${explode[41]//\"}
	paramter_3_name=${explode[43]//\"}
	paramter_3_notification_threshold=${explode[45]//\"}
	paramter_4_name=${explode[47]//\"}
	paramter_4_notification_threshold=${explode[49]//\"}
	paramter_5_name=${explode[51]//\"}
	paramter_5_notification_threshold=${explode[53]//\"}
	
	
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
		if [[ -z $nas_name ]]; then
			nas_name=`snmpwalk -v3 -l authPriv -u $SNMP_user -a MD5 -A $AuthPass1 -x AES -X $PrivPass2 $nas_url:161 SNMPv2-MIB::sysName.0 -Ovqt`
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
								if [ $disk_SMART_attribute_raw -gt $paramter_1_notification_threshold ]; then
									echo "$disk_SMART_attribute_name has exceeded its threshold value of $paramter_1_notification_threshold on disk $disk_path, sending email"
									mailbody="Warning SMART Attribute $disk_SMART_attribute_name on disk $disk_path on $nas_name has exceed the threshold value of $paramter_1_notification_threshold. It currently is reporting a value of $disk_SMART_attribute_raw"
									echo "from: $email_address " > $config_file_location/email_notification.txt
									echo "to: $email_address " >> $config_file_location/email_notification.txt
									echo "subject: $disk_path SMART ALERT for $nas_name " >> $config_file_location/email_notification.txt
									echo "" >> $config_file_location/email_notification.txt
									echo $mailbody >> $config_file_location/email_notification.txt
									cat $config_file_location/email_notification.txt | sendmail -t
								fi
							fi
							
							if [[ $disk_SMART_attribute_name == $paramter_2_name ]]; then
								if [ $disk_SMART_attribute_raw -gt $paramter_2_notification_threshold ]; then
									echo "$disk_SMART_attribute_name has exceeded its threshold value of $paramter_2_notification_threshold on disk $disk_path, sending email"
									mailbody="Warning SMART Attribute $disk_SMART_attribute_name on disk $disk_path on $nas_name has exceed the threshold value of $paramter_2_notification_threshold. It currently is reporting a value of $disk_SMART_attribute_raw"
									echo "from: $email_address " > $config_file_location/email_notification.txt
									echo "to: $email_address " >> $config_file_location/email_notification.txt
									echo "subject: $disk_path SMART ALERT for $nas_name " >> $config_file_location/email_notification.txt
									echo "" >> $config_file_location/email_notification.txt
									echo $mailbody >> $config_file_location/email_notification.txt
									cat $config_file_location/email_notification.txt | sendmail -t
								fi
							fi
							
							if [[ $disk_SMART_attribute_name == $paramter_3_name ]]; then
								if [ $disk_SMART_attribute_raw -gt $paramter_3_notification_threshold ]; then
									echo "$disk_SMART_attribute_name has exceeded its threshold value of $paramter_3_notification_threshold on disk $disk_path, sending email"
									mailbody="Warning SMART Attribute $disk_SMART_attribute_name on disk $disk_path on $nas_name has exceed the threshold value of $paramter_3_notification_threshold. It currently is reporting a value of $disk_SMART_attribute_raw"
									echo "from: $email_address " > $config_file_location/email_notification.txt
									echo "to: $email_address " >> $config_file_location/email_notification.txt
									echo "subject: $disk_path SMART ALERT for $nas_name " >> $config_file_location/email_notification.txt
									echo "" >> $config_file_location/email_notification.txt
									echo $mailbody >> $config_file_location/email_notification.txt
									cat $config_file_location/email_notification.txt | sendmail -t
								fi
							fi
							
							if [[ $disk_SMART_attribute_name == $paramter_4_name ]]; then
								if [ $disk_SMART_attribute_raw -gt $paramter_4_notification_threshold ]; then
									echo "$disk_SMART_attribute_name has exceeded its threshold value of $paramter_4_notification_threshold on disk $disk_path, sending email"
									mailbody="Warning SMART Attribute $disk_SMART_attribute_name on disk $disk_path on $nas_name has exceed the threshold value of $paramter_4_notification_threshold. It currently is reporting a value of $disk_SMART_attribute_raw"
									echo "from: $email_address " > $config_file_location/email_notification.txt
									echo "to: $email_address " >> $config_file_location/email_notification.txt
									echo "subject: $disk_path SMART ALERT for $nas_name " >> $config_file_location/email_notification.txt
									echo "" >> $config_file_location/email_notification.txt
									echo $mailbody >> $config_file_location/email_notification.txt
									cat $config_file_location/email_notification.txt | sendmail -t
								fi
							fi
							
							if [[ $disk_SMART_attribute_name == $paramter_5_name ]]; then
								if [ $disk_SMART_attribute_raw -gt $paramter_5_notification_threshold ]; then
									echo "$disk_SMART_attribute_name has exceeded its threshold value of $paramter_5_notification_threshold on disk $disk_path, sending email"
									mailbody="Warning SMART Attribute $disk_SMART_attribute_name on disk $disk_path on $nas_name has exceed the threshold value of $paramter_5_notification_threshold. It currently is reporting a value of $disk_SMART_attribute_raw"
									echo "from: $email_address " > $config_file_location/email_notification.txt
									echo "to: $email_address " >> $config_file_location/email_notification.txt
									echo "subject: $disk_path SMART ALERT for $nas_name " >> $config_file_location/email_notification.txt
									echo "" >> $config_file_location/email_notification.txt
									echo $mailbody >> $config_file_location/email_notification.txt
									cat $config_file_location/email_notification.txt | sendmail -t
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
					echo "from: $email_address " > $config_file_location/email_notification.txt
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
				curl -i -XPOST "http://$influxdb_host:$influxdb_port/write?u=$influxdb_user&p=$influxdb_pass&db=$influxdb_name" --data-binary "$post_url"
			else
				#if using influxdb version 2.x.x
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
