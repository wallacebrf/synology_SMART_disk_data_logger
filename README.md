<div id="top"></div>
<!--
*** comments....
-->



<!-- PROJECT LOGO -->
<br />

<h3 align="center">Synology Disk SMART Attribute Logger to InfluxDB</h3>

  <p align="center">

	!!!NOTICE!!!   !!!NOTICE!!!    !!!NOTICE!!!
 	This script has now been replaced with a MUCH simplier but also MUCH faster script using "smartctl" instead of SNMP. It can be found here: https://github.com/wallacebrf/SMART-to-InfluxDB-Logger
  	This script using SNMP took 1 minute and 22 seconds to execute on a Synology NAS with 9x HDDs and no NVME drives
   ```
	root@Server_NVR:/volume1/web/logging# time bash synology_SMART_snmp.sh
	Capturing 1 times
	no NVME drives installed, skipping NVME capture
	Capture #1 complete
	
	real    1m22.314s
	user    0m30.592s
	sys     0m9.620s
```
	However the new script running on the same system took slightly more than 2 seconds to execute on the same system

 	the new script is a drop in replacement for this SNMP script as it uses the same config file. Please replace the .sh file and the .php files used by this script with the ones for the new script. 

```
root@Server_NVR:/volume1/web/logging# time bash smart.sh
no NVME drives installed, skipping NVME capture

real    0m2.218s
user    0m0.960s
sys     0m0.195s
```
    
	  
   This project is comprised of a shell script that runs as often as desired (I recommend every 12 hours) collecting data from DSM pertaining to the SMART attributes for all drives installed within the system and placing it into InfluxDB. This script will also send email notifications of up to 20x drive SMART parameters are either above, equal to, or below a value of your choice. This script also now supports NVME disk SMART data collection if NVME drives are installed within the system. 
    <br />
    <a href="https://github.com/wallacebrf/synology_SMART_disk_data_logger"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/wallacebrf/synology_SMART_disk_data_logger/issues">Report Bug</a>
    ·
    <a href="https://github.com/wallacebrf/synology_SMART_disk_data_logger/issues">Request Feature</a>
  </p>
</div>



<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#About_the_project_Details">About The Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#roadmap">Road map</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
### About_the_project_Details

<img src="https://raw.githubusercontent.com/wallacebrf/synology_SMART_disk_data_logger/main/Images/SMART_dashboard.webp" alt="1313">

The script collects Disk SMART details for SATA drives from a Synology NAS using SNMP version 3 (much more secure than version 2) and saves data to InfluxDB. This script will also send email notifications for up to 20x drive SMART parameters that are either above, equal to, or below a configurable value in a basic web interface. 

The script also collects NVME drive SMART data if NVME disks are installed. NVME data is not available over SNMP in Synology DSM, so the data is collected from the "nvme" command. 

<!-- GETTING STARTED -->
## Getting Started

This project is written around a Synology NAS and their DSM specific SNMP OIDs and MIBs. This script will not function on a different vendor system. 

### Prerequisites

1. This script requires the installation of the Synology MailPlus server package in order to send emails. If the package is not installed, the script will operate normally with the exception of being unable to send notification emails. 

The mail plus server package must be properly configured to relay notification emails. NOTE: this read-me DOES NOT explain how to properly configure mail plus server. 

2. This script only supports SNMP V3. This is because lower versions are less secure. SNMP must be enabled on the host NAS (details below).
		
3. This script can be run through Synology Task Scheduler with a recommended operating frequency is every 12 hours. Details on configuring task schedule are below. 
		
4. This project requires a PHP server to be installed and configured through the web-station package to allow the web-administrative page to be available. This read-me does explain how to configure the needed read/write permissions of the web-station "http" user, but does not otherwise explain how to setup a website on a Synology NAS through web-station. 


### Installation

Note: This README assumes InfluxDB version 2.0 or higher and Grafana are already installed and properly configured. This read-me does NOT explain how to install and configure InfluxDB nor Grafana. 

1. Create the following directories on the NAS

```
1. %PHP_Server_Root%/config
2. %PHP_Server_Root%/logging
3. %PHP_Server_Root%/logging/notifications
```

note: ```%PHP_Server_Root%``` is what ever shared folder location the PHP web server root directory is configured to be within web station.

2. Place the ```functions.php``` file in the root of the PHP web server running on the NAS (typically this will be ```/volume1/web```)

3. Place the ```synology_SMART_snmp.sh``` file in the ```/logging``` directory

4. Place the ```SMART_server2_config.php``` file in the ```/config``` directory

### Configuration "synology_SMART_snmp.sh"

1. Open the ```synology_SMART_snmp.sh``` file in a text editor. I suggest Notepad++
2. the script contains the following configuration variables
```
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
```

for ```config_file_location``` ensure the path is the same as the directory ```%PHP_Server_Root%/config``` that was previously created. 

for ```email_contents``` ensure the path is the same as the directory ```%PHP_Server_Root%/logging/notifications``` that was previously created. 

for ```lock_file_location``` ensure the path is the same as the directory ```%PHP_Server_Root%/logging/notifications``` that was previously created. 

For the ```EMAIL SETTINGS USED IF CONFIGURATION FILE IS UNAVAILABLE``` settings, configure the email address details as desired.


3. Delete the the following lines as those are for my personal use as I use this script for several units that have slightly different configurations	
```
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
```


### Configuration "SMART_server2_config.php"

1. Open the ```SMART_server2_config.php``` file in a text editor
2. the script contains the following configuration variables
```
$config_file="/volume1/web/config/config_files/config_files_local/smart_logging_config.txt";
$use_login_sessions=true; //set to false if not using user login sessions
$form_submittal_destination="index.php?page=6&config_page=smart_server2"; //set to the destination the HTML form submit should be directed to
$page_title="Server2 SMART Logging and Notification Configuration Settings";
```

ENSURE THE VALUES FOR ```$config_file``` ARE THE SAME AS THAT CONFIGURED IN [Configuration "synology_SMART_snmp.sh"] FOR THE VARIABLE ```config_file_location```

The ```form_submittal_destination``` can either be set to the name of the "SMART_server2_config.php" file itself if accessing the php file directly in the browser address bar, or if the "SMART_server2_config.php" file is embedded in another PHP file using an "include_once" then the location should be to that php file as the included example currently shows. 

The variable ```page_title``` controls the title of the page when viewing it in a browser. 

The SMART_server2_config.php file by default automatically redirects from HTTP to HTTPS. If this behavior is not required or desired, change the ```use_login_sessions``` to false. the setting should only be set to true if using active user log-in sessions in your PHP web site for stronger access control. 

### Configuration of Synology web server "http" user permissions

By default the Synology user "http" utilized by web station does not have write permissions to the "web" file share. Note, in this example, it is assumed the "web" file share is the directory web station will use for its ```%PHP_Server_Root%```. If a different shared folder is used, adjust accordingly. 

1. Go to Control Panel -> User & Group -> "Group" tab
2. Click on the "http" user and press the "edit" button
3. Go to the "permissions" tab
4. Scroll down the list of shared folders to find "web" and click on the right checkbox under "customize" 
5. Check ALL boxes and click "done"
6. Verify the window indicates the "http" user group has "Full Control" and click the checkbox at the bottom "Apply to this folder, sub folders and files" and click "Save"

<img src="https://raw.githubusercontent.com/wallacebrf/synology_snmp/main/Images/http_user1.png" alt="1313">
<img src="https://raw.githubusercontent.com/wallacebrf/synology_snmp/main/Images/http_user2.png" alt="1314">
<img src="https://raw.githubusercontent.com/wallacebrf/synology_snmp/main/Images/http_user3.png" alt="1314">

### Configuration of Synology SNMP settings

By default Synology DSM does not have SNMP settings enabled. This script requires them to be enabled. 

1. Control Panel -> Terminal & SNMP -> "SNMP" tab
2. Check the box "Enable SNMP Service"
3. Leave the following box UNCHECKED "SNMPv1, SNMPv2c service" as we only want SNMP version 3
4. Check the box "SNMPv3 service"
5. Enter a "Username" without spaces, choose a "protocol" and "password"
6. Ensure the "Enable SNMP privacy" is checked and enter a desired protocol and a password. it may be the same password used above or can be a different password
7. Click apply to save the settings

Document all of the protocols, passwords and user information entered in Synology Control panel as this same information will need to entered into the configuration web page in future steps of this REDAME

NOTE: If firewall rules are enabled on the Synology system, the SNMP service port may need to be opened if this script is not running on this particular physical server. This set of instructions will not detail how to configure firewall rules. 

<img src="https://raw.githubusercontent.com/wallacebrf/synology_snmp/main/Images/snmp1.png" alt="1313">


### Configuration of required settings

<img src="https://raw.githubusercontent.com/wallacebrf/synology_SMART_disk_data_logger/main/Images/web-page-config2.png" alt="1313">

1. Now that the files are where they need to be, using a browser go to the "SMART_server2_config.php" page for example ```http://<NAS-IP>/config/SMART_server2_config.php```. When the page loads for the first time, it will automatically create a "smart_logging_config.txt" in the config directory created previously. The values will all be default values and must be configured or the script will not operate. 
2. Ensure the script is enabled
3. Leave "Capture Interval [Seconds]" set to 60 seconds
4. Configure email settings, the destination email address, the from email address
5. Enter the details for influxDB.
--> for InfluxDB 2, the "database" will be the randomly generated string identifying the data bucket, for example "a6878dc5c298c712"
--> for InfluxDB 2, the "User Name of Influx DB" can be left as the default value as this is NOT required for InfluxDB version 2 and higher. 
--> for InfluxDB 2, the "Password" is the API access key / Authorization Token. 
6. Configure the SNMP settings. These settings must match the settings the NAS has been configured to use as configured previously. 
7. Configure the SMART notification settings. NOTE: these settings will need to be changed after the script is run for the first time. This is due to every drive using different SMART parameter names. The parameter names entered into the configuration page will need to match what is gathered from your system. 

### Test running the ```synology_SMART_disk_data_logger.sh``` file for the first time

Now that the required configuration files are made using the web-interface, we can ensure the bash script operates correctly. 

1. Open the ```synology_SMART_disk_data_logger.sh``` file for editing. Find the line ```debug=0``` and change to ```debug=1``` to enable verbose output to assist with debugging
2. Open SSH and navigate to where the ```synology_SMART_disk_data_logger.sh``` file is located. Type the following command ```bash synology_SMART_disk_data_logger.sh``` and press enter
3. The script will run and load all of the configuration settings. In debug mode it will print out details of your system. It will indicate if MailPlus is installed, and will display the values of each drive's parameters. Here is the output from one of my systems with 9x drives installed. NOTE: Data for only one drive is shown for brevity.
```
MailPlus Server is installed and running
Synology SNTP settings are not Blank
Capturing 1 times
SMART data for disk "/dev/sata1":
Raw_Read_Error_Rate: ID: 1 || Current Value: 100 || Worst Value: 100 || Threshold: 16 || RAW Value: 0 || Status: "OK"
SMART data for disk "/dev/sata1":
Throughput_Performance: ID: 2 || Current Value: 130 || Worst Value: 130 || Threshold: 54 || RAW Value: 100 || Status: "OK"
SMART data for disk "/dev/sata1":
Spin_Up_Time: ID: 3 || Current Value: 165 || Worst Value: 165 || Threshold: 24 || RAW Value: 399 || Status: "OK"
SMART data for disk "/dev/sata1":
Start_Stop_Count: ID: 4 || Current Value: 100 || Worst Value: 100 || Threshold: 0 || RAW Value: 51 || Status: "OK"
SMART data for disk "/dev/sata1":
Reallocated_Sector_Ct: ID: 5 || Current Value: 100 || Worst Value: 100 || Threshold: 5 || RAW Value: 0 || Status: "OK"
SMART data for disk "/dev/sata1":
Seek_Error_Rate: ID: 7 || Current Value: 100 || Worst Value: 100 || Threshold: 67 || RAW Value: 0 || Status: "OK"
SMART data for disk "/dev/sata1":
Seek_Time_Performance: ID: 8 || Current Value: 128 || Worst Value: 128 || Threshold: 20 || RAW Value: 18 || Status: "OK"
SMART data for disk "/dev/sata1":
Power_On_Hours: ID: 9 || Current Value: 96 || Worst Value: 96 || Threshold: 0 || RAW Value: 31780 || Status: "OK"
SMART data for disk "/dev/sata1":
Spin_Retry_Count: ID: 10 || Current Value: 100 || Worst Value: 100 || Threshold: 60 || RAW Value: 0 || Status: "OK"
SMART data for disk "/dev/sata1":
Power_Cycle_Count: ID: 12 || Current Value: 100 || Worst Value: 100 || Threshold: 0 || RAW Value: 51 || Status: "OK"
SMART data for disk "/dev/sata1":
Helium_Level: ID: 22 || Current Value: 100 || Worst Value: 100 || Threshold: 25 || RAW Value: 100 || Status: "OK"
SMART data for disk "/dev/sata1":
Power-Off_Retract_Count: ID: 192 || Current Value: 100 || Worst Value: 100 || Threshold: 0 || RAW Value: 1160 || Status: "OK"
SMART data for disk "/dev/sata1":
Load_Cycle_Count: ID: 193 || Current Value: 100 || Worst Value: 100 || Threshold: 0 || RAW Value: 1160 || Status: "OK"
SMART data for disk "/dev/sata1":
Temperature_Celsius: ID: 194 || Current Value: 206 || Worst Value: 206 || Threshold: 0 || RAW Value: 29 || Status: "OK"
SMART data for disk "/dev/sata1":
Reallocated_Event_Count: ID: 196 || Current Value: 100 || Worst Value: 100 || Threshold: 0 || RAW Value: 0 || Status: "OK"
SMART data for disk "/dev/sata1":
Current_Pending_Sector: ID: 197 || Current Value: 100 || Worst Value: 100 || Threshold: 0 || RAW Value: 0 || Status: "OK"
SMART data for disk "/dev/sata1":
Offline_Uncorrectable: ID: 198 || Current Value: 100 || Worst Value: 100 || Threshold: 0 || RAW Value: 0 || Status: "OK"
SMART data for disk "/dev/sata1":
UDMA_CRC_Error_Count: ID: 199 || Current Value: 200 || Worst Value: 200 || Threshold: 0 || RAW Value: 0 || Status: "OK"

#Start of data imported into InfluxDB
synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata1,smart_attribute=**Raw_Read_Error_Rate** ID=1,current_value=100,worst_value=100,threshold_value=16,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata1,smart_attribute=**Throughput_Performance** ID=2,current_value=130,worst_value=130,threshold_value=54,RAW_value=100,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata1,smart_attribute=**Spin_Up_Time** ID=3,current_value=165,worst_value=165,threshold_value=24,RAW_value=399,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata1,smart_attribute=Start_Stop_Count ID=4,current_value=100,worst_value=100,threshold_value=0,RAW_value=51,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata1,smart_attribute=Reallocated_Sector_Ct ID=5,current_value=100,worst_value=100,threshold_value=5,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata1,smart_attribute=Seek_Error_Rate ID=7,current_value=100,worst_value=100,threshold_value=67,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata1,smart_attribute=Seek_Time_Performance ID=8,current_value=128,worst_value=128,threshold_value=20,RAW_value=18,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata1,smart_attribute=Power_On_Hours ID=9,current_value=96,worst_value=96,threshold_value=0,RAW_value=31780,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata1,smart_attribute=Spin_Retry_Count ID=10,current_value=100,worst_value=100,threshold_value=60,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata1,smart_attribute=Power_Cycle_Count ID=12,current_value=100,worst_value=100,threshold_value=0,RAW_value=51,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata1,smart_attribute=Helium_Level ID=22,current_value=100,worst_value=100,threshold_value=25,RAW_value=100,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata1,smart_attribute=Power-Off_Retract_Count ID=192,current_value=100,worst_value=100,threshold_value=0,RAW_value=1160,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata1,smart_attribute=Load_Cycle_Count ID=193,current_value=100,worst_value=100,threshold_value=0,RAW_value=1160,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata1,smart_attribute=Temperature_Celsius ID=194,current_value=206,worst_value=206,threshold_value=0,RAW_value=29,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata1,smart_attribute=Reallocated_Event_Count ID=196,current_value=100,worst_value=100,threshold_value=0,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata1,smart_attribute=Current_Pending_Sector ID=197,current_value=100,worst_value=100,threshold_value=0,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata1,smart_attribute=Offline_Uncorrectable ID=198,current_value=100,worst_value=100,threshold_value=0,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata1,smart_attribute=UDMA_CRC_Error_Count ID=199,current_value=200,worst_value=200,threshold_value=0,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata1 disk_status=1
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata2,smart_attribute=**Raw_Read_Error_Rate** ID=1,current_value=100,worst_value=100,threshold_value=16,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata2,smart_attribute=**Throughput_Performance** ID=2,current_value=130,worst_value=130,threshold_value=54,RAW_value=100,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata2,smart_attribute=**Spin_Up_Time** ID=3,current_value=158,worst_value=158,threshold_value=24,RAW_value=415,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata2,smart_attribute=Start_Stop_Count ID=4,current_value=100,worst_value=100,threshold_value=0,RAW_value=51,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata2,smart_attribute=Reallocated_Sector_Ct ID=5,current_value=100,worst_value=100,threshold_value=5,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata2,smart_attribute=Seek_Error_Rate ID=7,current_value=100,worst_value=100,threshold_value=67,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata2,smart_attribute=Seek_Time_Performance ID=8,current_value=128,worst_value=128,threshold_value=20,RAW_value=18,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata2,smart_attribute=Power_On_Hours ID=9,current_value=96,worst_value=96,threshold_value=0,RAW_value=31780,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata2,smart_attribute=Spin_Retry_Count ID=10,current_value=100,worst_value=100,threshold_value=60,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata2,smart_attribute=Power_Cycle_Count ID=12,current_value=100,worst_value=100,threshold_value=0,RAW_value=51,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata2,smart_attribute=Helium_Level ID=22,current_value=100,worst_value=100,threshold_value=25,RAW_value=100,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata2,smart_attribute=Power-Off_Retract_Count ID=192,current_value=100,worst_value=100,threshold_value=0,RAW_value=1150,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata2,smart_attribute=Load_Cycle_Count ID=193,current_value=100,worst_value=100,threshold_value=0,RAW_value=1150,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata2,smart_attribute=Temperature_Celsius ID=194,current_value=206,worst_value=206,threshold_value=0,RAW_value=29,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata2,smart_attribute=Reallocated_Event_Count ID=196,current_value=100,worst_value=100,threshold_value=0,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata2,smart_attribute=Current_Pending_Sector ID=197,current_value=100,worst_value=100,threshold_value=0,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata2,smart_attribute=Offline_Uncorrectable ID=198,current_value=100,worst_value=100,threshold_value=0,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata2,smart_attribute=UDMA_CRC_Error_Count ID=199,current_value=200,worst_value=200,threshold_value=0,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata2 disk_status=1
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata3,smart_attribute=**Raw_Read_Error_Rate** ID=1,current_value=100,worst_value=100,threshold_value=16,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata3,smart_attribute=**Throughput_Performance** ID=2,current_value=132,worst_value=132,threshold_value=54,RAW_value=96,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata3,smart_attribute=**Spin_Up_Time** ID=3,current_value=159,worst_value=159,threshold_value=24,RAW_value=412,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata3,smart_attribute=Start_Stop_Count ID=4,current_value=100,worst_value=100,threshold_value=0,RAW_value=54,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata3,smart_attribute=Reallocated_Sector_Ct ID=5,current_value=100,worst_value=100,threshold_value=5,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata3,smart_attribute=Seek_Error_Rate ID=7,current_value=100,worst_value=100,threshold_value=67,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata3,smart_attribute=Seek_Time_Performance ID=8,current_value=128,worst_value=128,threshold_value=20,RAW_value=18,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata3,smart_attribute=Power_On_Hours ID=9,current_value=96,worst_value=96,threshold_value=0,RAW_value=31780,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata3,smart_attribute=Spin_Retry_Count ID=10,current_value=100,worst_value=100,threshold_value=60,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata3,smart_attribute=Power_Cycle_Count ID=12,current_value=100,worst_value=100,threshold_value=0,RAW_value=54,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata3,smart_attribute=Helium_Level ID=22,current_value=100,worst_value=100,threshold_value=25,RAW_value=100,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata3,smart_attribute=Power-Off_Retract_Count ID=192,current_value=100,worst_value=100,threshold_value=0,RAW_value=1154,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata3,smart_attribute=Load_Cycle_Count ID=193,current_value=100,worst_value=100,threshold_value=0,RAW_value=1154,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata3,smart_attribute=Temperature_Celsius ID=194,current_value=222,worst_value=222,threshold_value=0,RAW_value=27,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata3,smart_attribute=Reallocated_Event_Count ID=196,current_value=100,worst_value=100,threshold_value=0,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata3,smart_attribute=Current_Pending_Sector ID=197,current_value=100,worst_value=100,threshold_value=0,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata3,smart_attribute=Offline_Uncorrectable ID=198,current_value=100,worst_value=100,threshold_value=0,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata3,smart_attribute=UDMA_CRC_Error_Count ID=199,current_value=200,worst_value=200,threshold_value=0,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata3 disk_status=1
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata4,smart_attribute=**Raw_Read_Error_Rate** ID=1,current_value=100,worst_value=100,threshold_value=16,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata4,smart_attribute=**Throughput_Performance** ID=2,current_value=132,worst_value=132,threshold_value=54,RAW_value=96,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata4,smart_attribute=**Spin_Up_Time** ID=3,current_value=157,worst_value=157,threshold_value=24,RAW_value=418,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata4,smart_attribute=Start_Stop_Count ID=4,current_value=100,worst_value=100,threshold_value=0,RAW_value=54,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata4,smart_attribute=Reallocated_Sector_Ct ID=5,current_value=100,worst_value=100,threshold_value=5,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata4,smart_attribute=Seek_Error_Rate ID=7,current_value=100,worst_value=100,threshold_value=67,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata4,smart_attribute=Seek_Time_Performance ID=8,current_value=128,worst_value=128,threshold_value=20,RAW_value=18,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata4,smart_attribute=Power_On_Hours ID=9,current_value=96,worst_value=96,threshold_value=0,RAW_value=31780,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata4,smart_attribute=Spin_Retry_Count ID=10,current_value=100,worst_value=100,threshold_value=60,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata4,smart_attribute=Power_Cycle_Count ID=12,current_value=100,worst_value=100,threshold_value=0,RAW_value=54,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata4,smart_attribute=Helium_Level ID=22,current_value=100,worst_value=100,threshold_value=25,RAW_value=100,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata4,smart_attribute=Power-Off_Retract_Count ID=192,current_value=100,worst_value=100,threshold_value=0,RAW_value=1157,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata4,smart_attribute=Load_Cycle_Count ID=193,current_value=100,worst_value=100,threshold_value=0,RAW_value=1157,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata4,smart_attribute=Temperature_Celsius ID=194,current_value=214,worst_value=214,threshold_value=0,RAW_value=28,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata4,smart_attribute=Reallocated_Event_Count ID=196,current_value=100,worst_value=100,threshold_value=0,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata4,smart_attribute=Current_Pending_Sector ID=197,current_value=100,worst_value=100,threshold_value=0,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata4,smart_attribute=Offline_Uncorrectable ID=198,current_value=100,worst_value=100,threshold_value=0,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata4,smart_attribute=UDMA_CRC_Error_Count ID=199,current_value=200,worst_value=200,threshold_value=0,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata4 disk_status=1
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata5,smart_attribute=**Raw_Read_Error_Rate** ID=1,current_value=100,worst_value=100,threshold_value=16,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata5,smart_attribute=**Throughput_Performance** ID=2,current_value=132,worst_value=132,threshold_value=54,RAW_value=96,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata5,smart_attribute=**Spin_Up_Time** ID=3,current_value=160,worst_value=160,threshold_value=24,RAW_value=412,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata5,smart_attribute=Start_Stop_Count ID=4,current_value=100,worst_value=100,threshold_value=0,RAW_value=47,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata5,smart_attribute=Reallocated_Sector_Ct ID=5,current_value=100,worst_value=100,threshold_value=5,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata5,smart_attribute=Seek_Error_Rate ID=7,current_value=100,worst_value=100,threshold_value=67,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata5,smart_attribute=Seek_Time_Performance ID=8,current_value=128,worst_value=128,threshold_value=20,RAW_value=18,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata5,smart_attribute=Power_On_Hours ID=9,current_value=96,worst_value=96,threshold_value=0,RAW_value=31573,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata5,smart_attribute=Spin_Retry_Count ID=10,current_value=100,worst_value=100,threshold_value=60,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata5,smart_attribute=Power_Cycle_Count ID=12,current_value=100,worst_value=100,threshold_value=0,RAW_value=17,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata5,smart_attribute=Helium_Level ID=22,current_value=100,worst_value=100,threshold_value=25,RAW_value=100,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata5,smart_attribute=Power-Off_Retract_Count ID=192,current_value=99,worst_value=99,threshold_value=0,RAW_value=1349,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata5,smart_attribute=Load_Cycle_Count ID=193,current_value=99,worst_value=99,threshold_value=0,RAW_value=1349,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata5,smart_attribute=Temperature_Celsius ID=194,current_value=214,worst_value=214,threshold_value=0,RAW_value=28,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata5,smart_attribute=Reallocated_Event_Count ID=196,current_value=100,worst_value=100,threshold_value=0,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata5,smart_attribute=Current_Pending_Sector ID=197,current_value=100,worst_value=100,threshold_value=0,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata5,smart_attribute=Offline_Uncorrectable ID=198,current_value=100,worst_value=100,threshold_value=0,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata5,smart_attribute=UDMA_CRC_Error_Count ID=199,current_value=200,worst_value=200,threshold_value=0,RAW_value=1,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata5 disk_status=1
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata7,smart_attribute=**Raw_Read_Error_Rate** ID=1,current_value=100,worst_value=100,threshold_value=16,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata7,smart_attribute=**Throughput_Performance** ID=2,current_value=130,worst_value=130,threshold_value=54,RAW_value=100,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata7,smart_attribute=**Spin_Up_Time** ID=3,current_value=161,worst_value=161,threshold_value=24,RAW_value=410,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata7,smart_attribute=Start_Stop_Count ID=4,current_value=100,worst_value=100,threshold_value=0,RAW_value=47,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata7,smart_attribute=Reallocated_Sector_Ct ID=5,current_value=100,worst_value=100,threshold_value=5,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata7,smart_attribute=Seek_Error_Rate ID=7,current_value=100,worst_value=100,threshold_value=67,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata7,smart_attribute=Seek_Time_Performance ID=8,current_value=140,worst_value=140,threshold_value=20,RAW_value=15,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata7,smart_attribute=Power_On_Hours ID=9,current_value=96,worst_value=96,threshold_value=0,RAW_value=31573,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata7,smart_attribute=Spin_Retry_Count ID=10,current_value=100,worst_value=100,threshold_value=60,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata7,smart_attribute=Power_Cycle_Count ID=12,current_value=100,worst_value=100,threshold_value=0,RAW_value=17,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata7,smart_attribute=Helium_Level ID=22,current_value=100,worst_value=100,threshold_value=25,RAW_value=100,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata7,smart_attribute=Power-Off_Retract_Count ID=192,current_value=99,worst_value=99,threshold_value=0,RAW_value=1314,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata7,smart_attribute=Load_Cycle_Count ID=193,current_value=99,worst_value=99,threshold_value=0,RAW_value=1314,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata7,smart_attribute=Temperature_Celsius ID=194,current_value=206,worst_value=206,threshold_value=0,RAW_value=29,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata7,smart_attribute=Reallocated_Event_Count ID=196,current_value=100,worst_value=100,threshold_value=0,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata7,smart_attribute=Current_Pending_Sector ID=197,current_value=100,worst_value=100,threshold_value=0,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata7,smart_attribute=Offline_Uncorrectable ID=198,current_value=100,worst_value=100,threshold_value=0,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata7,smart_attribute=UDMA_CRC_Error_Count ID=199,current_value=200,worst_value=200,threshold_value=0,RAW_value=2,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata7 disk_status=1
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata8,smart_attribute=**Raw_Read_Error_Rate** ID=1,current_value=100,worst_value=100,threshold_value=16,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata8,smart_attribute=**Throughput_Performance** ID=2,current_value=132,worst_value=132,threshold_value=54,RAW_value=96,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata8,smart_attribute=**Spin_Up_Time** ID=3,current_value=161,worst_value=161,threshold_value=24,RAW_value=407,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata8,smart_attribute=Start_Stop_Count ID=4,current_value=100,worst_value=100,threshold_value=0,RAW_value=47,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata8,smart_attribute=Reallocated_Sector_Ct ID=5,current_value=100,worst_value=100,threshold_value=5,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata8,smart_attribute=Seek_Error_Rate ID=7,current_value=100,worst_value=100,threshold_value=67,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata8,smart_attribute=Seek_Time_Performance ID=8,current_value=128,worst_value=128,threshold_value=20,RAW_value=18,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata8,smart_attribute=Power_On_Hours ID=9,current_value=96,worst_value=96,threshold_value=0,RAW_value=31573,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata8,smart_attribute=Spin_Retry_Count ID=10,current_value=100,worst_value=100,threshold_value=60,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata8,smart_attribute=Power_Cycle_Count ID=12,current_value=100,worst_value=100,threshold_value=0,RAW_value=17,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata8,smart_attribute=Helium_Level ID=22,current_value=100,worst_value=100,threshold_value=25,RAW_value=100,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata8,smart_attribute=Power-Off_Retract_Count ID=192,current_value=99,worst_value=99,threshold_value=0,RAW_value=1312,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata8,smart_attribute=Load_Cycle_Count ID=193,current_value=99,worst_value=99,threshold_value=0,RAW_value=1312,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata8,smart_attribute=Temperature_Celsius ID=194,current_value=200,worst_value=200,threshold_value=0,RAW_value=30,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata8,smart_attribute=Reallocated_Event_Count ID=196,current_value=100,worst_value=100,threshold_value=0,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata8,smart_attribute=Current_Pending_Sector ID=197,current_value=100,worst_value=100,threshold_value=0,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata8,smart_attribute=Offline_Uncorrectable ID=198,current_value=100,worst_value=100,threshold_value=0,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata8,smart_attribute=UDMA_CRC_Error_Count ID=199,current_value=200,worst_value=200,threshold_value=0,RAW_value=2,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata8 disk_status=1
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata9,smart_attribute=**Raw_Read_Error_Rate** ID=1,current_value=100,worst_value=100,threshold_value=16,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata9,smart_attribute=**Throughput_Performance** ID=2,current_value=130,worst_value=130,threshold_value=54,RAW_value=100,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata9,smart_attribute=**Spin_Up_Time** ID=3,current_value=157,worst_value=157,threshold_value=24,RAW_value=418,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata9,smart_attribute=Start_Stop_Count ID=4,current_value=100,worst_value=100,threshold_value=0,RAW_value=32,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata9,smart_attribute=Reallocated_Sector_Ct ID=5,current_value=100,worst_value=100,threshold_value=5,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata9,smart_attribute=Seek_Error_Rate ID=7,current_value=100,worst_value=100,threshold_value=67,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata9,smart_attribute=Seek_Time_Performance ID=8,current_value=140,worst_value=140,threshold_value=20,RAW_value=15,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata9,smart_attribute=Power_On_Hours ID=9,current_value=98,worst_value=98,threshold_value=0,RAW_value=19203,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata9,smart_attribute=Spin_Retry_Count ID=10,current_value=100,worst_value=100,threshold_value=60,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata9,smart_attribute=Power_Cycle_Count ID=12,current_value=100,worst_value=100,threshold_value=0,RAW_value=15,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata9,smart_attribute=Helium_Level ID=22,current_value=100,worst_value=100,threshold_value=25,RAW_value=100,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata9,smart_attribute=Power-Off_Retract_Count ID=192,current_value=100,worst_value=100,threshold_value=0,RAW_value=806,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata9,smart_attribute=Load_Cycle_Count ID=193,current_value=100,worst_value=100,threshold_value=0,RAW_value=806,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata9,smart_attribute=Temperature_Celsius ID=194,current_value=200,worst_value=200,threshold_value=0,RAW_value=30,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata9,smart_attribute=Reallocated_Event_Count ID=196,current_value=100,worst_value=100,threshold_value=0,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata9,smart_attribute=Current_Pending_Sector ID=197,current_value=100,worst_value=100,threshold_value=0,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata9,smart_attribute=Offline_Uncorrectable ID=198,current_value=100,worst_value=100,threshold_value=0,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata9,smart_attribute=UDMA_CRC_Error_Count ID=199,current_value=200,worst_value=200,threshold_value=0,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata9 disk_status=1
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata6,smart_attribute=**Raw_Read_Error_Rate** ID=1,current_value=100,worst_value=100,threshold_value=16,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata6,smart_attribute=**Throughput_Performance** ID=2,current_value=132,worst_value=132,threshold_value=54,RAW_value=96,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata6,smart_attribute=**Spin_Up_Time** ID=3,current_value=161,worst_value=161,threshold_value=24,RAW_value=408,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata6,smart_attribute=Start_Stop_Count ID=4,current_value=100,worst_value=100,threshold_value=0,RAW_value=47,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata6,smart_attribute=Reallocated_Sector_Ct ID=5,current_value=100,worst_value=100,threshold_value=5,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata6,smart_attribute=Seek_Error_Rate ID=7,current_value=100,worst_value=100,threshold_value=67,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata6,smart_attribute=Seek_Time_Performance ID=8,current_value=128,worst_value=128,threshold_value=20,RAW_value=18,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata6,smart_attribute=Power_On_Hours ID=9,current_value=96,worst_value=96,threshold_value=0,RAW_value=31573,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata6,smart_attribute=Spin_Retry_Count ID=10,current_value=100,worst_value=100,threshold_value=60,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata6,smart_attribute=Power_Cycle_Count ID=12,current_value=100,worst_value=100,threshold_value=0,RAW_value=17,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata6,smart_attribute=Helium_Level ID=22,current_value=100,worst_value=100,threshold_value=25,RAW_value=100,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata6,smart_attribute=Power-Off_Retract_Count ID=192,current_value=99,worst_value=99,threshold_value=0,RAW_value=1309,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata6,smart_attribute=Load_Cycle_Count ID=193,current_value=99,worst_value=99,threshold_value=0,RAW_value=1309,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata6,smart_attribute=Temperature_Celsius ID=194,current_value=206,worst_value=206,threshold_value=0,RAW_value=29,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata6,smart_attribute=Reallocated_Event_Count ID=196,current_value=100,worst_value=100,threshold_value=0,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata6,smart_attribute=Current_Pending_Sector ID=197,current_value=100,worst_value=100,threshold_value=0,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata6,smart_attribute=Offline_Uncorrectable ID=198,current_value=100,worst_value=100,threshold_value=0,RAW_value=0,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata6,smart_attribute=UDMA_CRC_Error_Count ID=199,current_value=200,worst_value=200,threshold_value=0,RAW_value=1,status="OK"
                synology_SMART_status2,nas_name=Server2,disk_path=/dev/sata6 disk_status=1

Capture #1 complete
```

NOTE: if ```MailPlus Server``` is not installed, the script will give warnings that it is not installed. If this is acceptable then ignore the warnings

4. At the end of the script, it will output the results from InfluxDB. Ensure you do NOT see any instances of the following

```{"code":"invalid","message":"unable to parse```

or

```No Such Instance currently exists at this OID```

or

```invalid number``` 

These errors indicate that InfluxDB cannot intake the data properly and debugging is needed. Ensure no other errors were listed in the script output and ensure all values of the configuration parameters displayed in debug mode were correct.

7.) After it is confirmed the script is working without errors and that it is confirmed that InfluxDB is receiving the data correctly, change the ```debug=1``` back to a ```debug=0``` 

8.) Now proceed with creating a scheduled task to run the script as often as desired. I recommend every 12 hours. 


### Configuration of Task Scheduler 

1. Control Panel -> Task Scheduler
2. Click ```Create -> Scheduled Task -> User-defined script```
3. Under "General Settings" name the script "Synology SMART" and choose the "root" user and ensure the task is enabled
4. Click the "Schedule" tab at the top of the window
5. Select "Run on the following days" and choose "Daily"
6. Under Time, set "First run time" to "11" and "00"
7. Under "Frequency" select every 12 hours
8. Under last run time select "23:00"
9. Go to the "Task Settings" tab
10. Leave "Send run details by email" un-checked
11. Under "Run command" enter "bash /volume1/web/logging/synology_SMART_snmp.sh" NOTE: ensure the ```/volume1/web``` is the same as your PHP server root directory
12. Click "ok" in the bottom right
13. Find the newly created task in your list, right click and select "run". when a confirmation window pops up, choose "yes"
14. Verify the script ran correctly by going into Influxdb and viewing the collected data and verify fresh data was just added. 


### Grafana Dashboards


Two dashboard JSON files are available. The entire dashboard is written around the new FLUX language which is more powerful and simpler to use. One used when monitoring a single Synology Unit. The other is for monitoring multiple Synology Units on a single dashboard. The current version supplied here shows the data for three different Synology units

the Dashboard requires the use of an add-on plug in from
https://grafana.com/grafana/plugins/mxswat-separator-panel/

there are three different items in the JSON that will need to be adjusted to match your installation. the first the bucket it is drawing data from. edit this to match your bucket name
```
from(bucket: \"Test/autogen\")
```

next, edit the name of the Synology NAS as reported by the script. 

```
r[\"nas_name\"] == \"Server-Plex\")
```

The data source will also need to be configured to pull data from Influx within Grafana. 




<!-- CONTRIBUTING -->
## Contributing

<p align="right">(<a href="#top">back to top</a>)</p>



<!-- LICENSE -->
## License

This is free to use code, use as you wish

<p align="right">(<a href="#top">back to top</a>)</p>



<!-- CONTACT -->
## Contact

Your Name - Brian Wallace - wallacebrf@hotmail.com

Project Link: [https://github.com/wallacebrf/synology_snmp)

<p align="right">(<a href="#top">back to top</a>)</p>



<!-- ACKNOWLEDGMENTS -->
## Acknowledgments


<p align="right">(<a href="#top">back to top</a>)</p>
