<?php
///////////////////////////////////////////////////
//User Defined Variables
///////////////////////////////////////////////////

$config_file="/volume1/web/config/config_files/config_files_local/smart_logging_config.txt";
$use_login_sessions=true; //set to false if not using user login sessions
$form_submittal_destination="index.php?page=6&config_page=smart_server2"; //set to the destination the HTML form submit should be directed to
$page_title="Server2 SMART Logging and Notification Configuration Settings";

///////////////////////////////////////////////////
//Beginning of configuration page
///////////////////////////////////////////////////
if($use_login_sessions){
	if($_SERVER['HTTPS']!="on") {

	$redirect= "https://".$_SERVER['HTTP_HOST'].$_SERVER['REQUEST_URI'];

	header("Location:$redirect"); } 

	// Initialize the session
	if(session_status() !== PHP_SESSION_ACTIVE) session_start();
	 
	// Check if the user is logged in, if not then redirect him to login page
	if(!isset($_SESSION["loggedin"]) || $_SESSION["loggedin"] !== true){
		header("location: login.php");
		exit;
	}
}
error_reporting(E_ALL ^ E_NOTICE);
include $_SERVER['DOCUMENT_ROOT']."/functions.php";
$SNMP_user_error="";
$capture_interval_error="";
$nas_url_error="";
$ups_group_error="";
$influxdb_host_error="";
$influxdb_port_error="";
$influxdb_name_error="";
$influxdb_user_error="";
$influxdb_pass_error="";
$script_enable_error="";
$AuthPass1_error="";
$PrivPass2_error="";
$influx_db_version_error="";
$influxdb_org_error="";
$enable_email_notifications_error="";
$email_address_error="";
$paramter_1_name_error="";
$paramter_1_notification_threshold_error="";
$paramter_2_name_error="";
$paramter_2_notification_threshold_error="";
$paramter_3_name_error="";
$paramter_3_notification_threshold_error="";
$paramter_4_name_error="";
$paramter_4_notification_threshold_error="";
$paramter_5_name_error="";
$paramter_5_notification_threshold_error="";
$from_email_address_error="";
$generic_error="";
$snmp_auth_protocol_error="";
$snmp_privacy_protocol_error="";
		

if(isset($_POST['submit_server_PDU'])){
	if (file_exists("".$config_file."")) {
		$data = file_get_contents("".$config_file."");
		$pieces = explode(",", $data);
	}
		   
	[$SNMP_user, $SNMP_user_error] = test_input_processing($_POST['SNMP_user'], $pieces[1], "name", 0, 0);
	
	if ($_POST['capture_interval']==10 || $_POST['capture_interval']==15 || $_POST['capture_interval']==30 || $_POST['capture_interval']==60){
		$capture_interval=htmlspecialchars($_POST['capture_interval']);
	}else{
		$capture_interval=$pieces[3];
	}
	
	[$nas_url, $nas_url_error] = test_input_processing($_POST['nas_url'], $pieces[5], "ip", 0, 0);
	
	[$influxdb_host, $influxdb_host_error] = test_input_processing($_POST['influxdb_host'], $pieces[11], "ip", 0, 0);
	
	[$influxdb_port, $influxdb_port_error] = test_input_processing($_POST['influxdb_port'], $pieces[13], "numeric", 0, 65000);	
	
	[$influxdb_name, $influxdb_name_error] = test_input_processing($_POST['influxdb_name'], $pieces[15], "name", 0, 0);
	
	[$influxdb_user, $influxdb_user_error] = test_input_processing($_POST['influxdb_user'], $pieces[17], "name", 0, 0);		

	[$influxdb_pass, $influxdb_pass_error] = test_input_processing($_POST['influxdb_pass'], $pieces[19], "password", 0, 0);	
	
	[$script_enable, $generic_error] = test_input_processing($_POST['script_enable'], "", "checkbox", 0, 0);
	
	[$AuthPass1, $AuthPass1_error] = test_input_processing($_POST['AuthPass1'], $pieces[23], "password", 0, 0);
	
	[$PrivPass2, $PrivPass2_error] = test_input_processing($_POST['PrivPass2'], $pieces[25], "password", 0, 0);
	
	[$influx_db_version, $influx_db_version_error] = test_input_processing($_POST['influx_db_version'], $pieces[27], "numeric", 1, 2);
	
	[$influxdb_org, $influxdb_org_error] = test_input_processing($_POST['influxdb_org'], $pieces[29], "name", 0, 0);
	
	[$enable_email_notifications, $enable_email_notifications_error] = test_input_processing($_POST['enable_email_notifications'], "", "checkbox", 0, 0);
	
	[$email_address, $email_address_error] = test_input_processing($_POST['email_address'], $pieces[33], "email", 0, 0);
	
	[$paramter_1_name, $paramter_1_name_error] = test_input_processing($_POST['paramter_1_name'], $pieces[35], "name", 0, 0);
	
	[$paramter_1_notification_threshold, $paramter_1_notification_threshold_error] = test_input_processing($_POST['paramter_1_notification_threshold'], $pieces[37], "numeric", 0, 10000);
	
	[$paramter_2_name, $paramter_2_name_error] = test_input_processing($_POST['paramter_2_name'], $pieces[39], "name", 0, 0);
	
	[$paramter_2_notification_threshold, $paramter_2_notification_threshold_error] = test_input_processing($_POST['paramter_2_notification_threshold'], $pieces[41], "numeric", 0, 10000);
	
	[$paramter_3_name, $paramter_3_name_error] = test_input_processing($_POST['paramter_3_name'], $pieces[43], "name", 0, 0);
	
	[$paramter_3_notification_threshold, $paramter_3_notification_threshold_error] = test_input_processing($_POST['paramter_3_notification_threshold'], $pieces[45], "numeric", 0, 10000);
	
	[$paramter_4_name, $paramter_4_name_error] = test_input_processing($_POST['paramter_4_name'], $pieces[47], "name", 0, 0);
	
	[$paramter_4_notification_threshold, $paramter_4_notification_threshold_error] = test_input_processing($_POST['paramter_4_notification_threshold'], $pieces[49], "numeric", 0, 10000);
	
	[$paramter_5_name, $paramter_5_name_error] = test_input_processing($_POST['paramter_5_name'], $pieces[51], "name", 0, 0);
	
	[$paramter_5_notification_threshold, $paramter_5_notification_threshold_error] = test_input_processing($_POST['paramter_5_notification_threshold'], $pieces[53], "numeric", 0, 10000);
	
	[$from_email_address, $from_email_address_error] = test_input_processing($_POST['from_email_address'], $pieces[55], "email", 0, 0);
	
	[$snmp_auth_protocol, $snmp_auth_protocol_error] = test_input_processing($_POST['snmp_auth_protocol'], $pieces[57], "name", 0, 0);
	
	[$snmp_privacy_protocol, $snmp_privacy_protocol_error] = test_input_processing($_POST['snmp_privacy_protocol'], $pieces[59], "name", 0, 0);
	
	$put_contents_string="".$SNMP_user.",".$capture_interval.",".$nas_url.",nas_name,NAS,".$influxdb_host.",".$influxdb_port.",".$influxdb_name.",".$influxdb_user.",".$influxdb_pass.",".$script_enable.",".$AuthPass1.",".$PrivPass2.",".$influx_db_version.",".$influxdb_org.",".$enable_email_notifications.",".$email_address.",".$paramter_1_name.",".$paramter_1_notification_threshold.",".$paramter_2_name.",".$paramter_2_notification_threshold.",".$paramter_3_name.",".$paramter_3_notification_threshold.",".$paramter_4_name.",".$paramter_4_notification_threshold.",".$paramter_5_name.",".$paramter_5_notification_threshold.",".$from_email_address.",".$snmp_auth_protocol.",".$snmp_privacy_protocol."";
		  
	
	if (file_put_contents("".$config_file."",$put_contents_string )==FALSE){
		print "<font color=\"red\">Error - could not save configuration</font>";
	}
		  
}else{
	if (file_exists("".$config_file."")) {
		$data = file_get_contents("".$config_file."");
		$pieces = explode(",", $data);
		$SNMP_user=$pieces[0];
		$capture_interval=$pieces[1];
		$nas_url=$pieces[2];
		$nas_name=$pieces[3];
		$ups_group=$pieces[4];
		$influxdb_host=$pieces[5];
		$influxdb_port=$pieces[6];
		$influxdb_name=$pieces[7];
		$influxdb_user=$pieces[8];
		$influxdb_pass=$pieces[9];
		$script_enable=$pieces[10];
		$AuthPass1=$pieces[11];
		$PrivPass2=$pieces[12];
		$influx_db_version=$pieces[13];
		$influxdb_org=$pieces[14];
		$enable_email_notifications=$pieces[15];
		$email_address=$pieces[16];
		$paramter_1_name=$pieces[17];
		$paramter_1_notification_threshold=$pieces[18];
		$paramter_2_name=$pieces[19];
		$paramter_2_notification_threshold=$pieces[20];
		$paramter_3_name=$pieces[21];
		$paramter_3_notification_threshold=$pieces[22];
		$paramter_4_name=$pieces[23];
		$paramter_4_notification_threshold=$pieces[24];
		$paramter_5_name=$pieces[25];
		$paramter_5_notification_threshold=$pieces[26];
		$from_email_address=$pieces[27];
		$snmp_auth_protocol=$pieces[28];
		$snmp_privacy_protocol=$pieces[29];
		
		
		/*echo "
		SNMP_user is ".$SNMP_user."<br>
		capture_interval is ".$capture_interval."<br>
		nas_url is ".$nas_url."<br>
		nas_name is ".$nas_name."<br>
		ups_group is ".$ups_group."<br>
		influxdb_host is ".$influxdb_host."<br>
		influxdb_port is ".$influxdb_port."<br>
		influxdb_name is ".$influxdb_name."<br>
		influxdb_user is ".$influxdb_user."<br>
		influxdb_pass is ".$influxdb_pass."<br>
		script_enable is ".$script_enable."<br>
		AuthPass1 is ".$AuthPass1."<br>
		PrivPass2 is ".$PrivPass2."<br>
		influx_db_version is ".$influx_db_version."<br>
		influxdb_org is ".$influxdb_org."<br>
		enable_email_notifications is ".$enable_email_notifications."<br>
		email_address is ".$email_address."<br>
		paramter_1_name is ".$paramter_1_name."<br>
		paramter_1_notification_threshold is ".$paramter_1_notification_threshold."<br>
		paramter_2_name is ".$paramter_2_name."<br>
		paramter_2_notification_threshold is ".$paramter_2_notification_threshold."<br>
		paramter_3_name is ".$paramter_3_name."<br>
		paramter_3_notification_threshold is ".$paramter_3_notification_threshold."<br>
		paramter_4_name is ".$paramter_4_name."<br>
		paramter_4_notification_threshold is ".$paramter_4_notification_threshold."<br>
		paramter_5_name is ".$paramter_5_name."<br>
		paramter_5_notification_threshold is ".$paramter_5_notification_threshold."<br>
		from_email_address is ".$from_email_address."<br>
		snmp_auth_protocol is ".$snmp_auth_protocol."<br>
		snmp_privacy_protocol is ".$snmp_privacy_protocol."<br>";*/
	}else{
		$put_contents_string="SNMP_user,60,0.0.0.0,nas_name,NAS,localhost,8086,influxdb_name,influxdb_user,influxdb_pass,0,AuthPass,PrivPass2,2,influxdb_org,0,email_address,paramter_1_name,0,paramter_2_name,0,paramter_3_name,0,paramter_4_name,0,paramter_5_name,0,from_email_address,MD5,AES";
			  
		if (file_put_contents("".$config_file."",$put_contents_string )==FALSE){
			print "<font color=\"red\">Error - could not save configuration</font>";
		}
	}
}
	   
	   print "
<br>
<fieldset>
	<legend>
		<h3>".$page_title."</h3>
	</legend>
	<table border=\"0\">
		<tr>
			<td>";
		if ($script_enable==1){
			print "<font color=\"green\"><h3>Script Status: Active</h3></font>";
		}else{
			print "<font color=\"red\"><h3>Script Status: Inactive</h3></font>";
		}
print "		</td>
		</tr>
		<tr>
			<td align=\"left\">
				<form action=\"".$form_submittal_destination."\" method=\"post\">
					<p><input type=\"checkbox\" name=\"script_enable\" value=\"1\" ";
					   if ($script_enable==1){
							print "checked";
					   }
print "					>Enable Entire Script?
					</p><br>
					<b>CAPTURE SETTINGS</b>
					<p>->Capture Interval [Seconds]: <input type=\"text\" name=\"capture_interval\" value=".$capture_interval."> ".$capture_interval_error."</p>
					<br>
					<b>EMAIL SETTINGS</b>
					<p>-><input type=\"checkbox\" name=\"enable_email_notifications\" value=\"1\" ";
					   if ($enable_email_notifications==1){
							print "checked";
					   }
print "					>Enable Email Notifications?
					</p>
					<p>->Recipient Email Address: <input type=\"text\" name=\"email_address\" value=".$email_address."> ".$email_address_error."</p>
					<p>->From Email Address: <input type=\"text\" name=\"from_email_address\" value=".$from_email_address."> ".$from_email_address_error."</p>
					<br>
					<b>INFLUXDB SETTINGS</b>
					<p>->IP of Influx DB: <input type=\"text\" name=\"influxdb_host\" value=".$influxdb_host."> ".$influxdb_host_error."</p>
					<p>->PORT of Influx DB: <input type=\"text\" name=\"influxdb_port\" value=".$influxdb_port."> ".$influxdb_port_error."</p>
					<p>->Database to use within Influx DB: <input type=\"text\" name=\"influxdb_name\" value=".$influxdb_name."> ".$influxdb_name_error."</p>
					<p>->User Name of Influx DB: <input type=\"text\" name=\"influxdb_user\" value=".$influxdb_user."> ".$influxdb_user_error." </p>
					<p>->Password of Influx DB: <input type=\"text\" name=\"influxdb_pass\" value=".$influxdb_pass."> ".$influxdb_pass_error."</p>
					<p>->Influx DB Version: <input type=\"text\" name=\"influx_db_version\" value=".$influx_db_version."> ".$influx_db_version_error."</p>
					<p>->Influx DB Org: <input type=\"text\" name=\"influxdb_org\" value=".$influxdb_org."> ".$influxdb_org_error."</p>
					<br>
					<b>SNMP SETTINGS</b>
					<p>->IP of Synology NAS: <input type=\"text\" name=\"nas_url\" value=".$nas_url."> ".$nas_url_error."</p>
					<p>->SNMP user: <input type=\"text\" name=\"SNMP_user\" value=".$SNMP_user."> ".$SNMP_user_error."</p>
					<p>->SNMP Authorization Password: <input type=\"text\" name=\"AuthPass1\" value=".$AuthPass1."> ".$AuthPass1_error."</p>
					<p>->SNMP Privacy Password: <input type=\"text\" name=\"PrivPass2\" value=".$PrivPass2."> ".$PrivPass2_error."</p>
					<p>->Authorization Protocol: <select name=\"snmp_auth_protocol\">";
					if ($snmp_auth_protocol=="MD5"){
						print "<option value=\"MD5\" selected>MD5</option>
						<option value=\"SHA\">SHA</option>";
					}else if ($snmp_auth_protocol=="SHA"){
						print "<option value=\"MD5\">MD5</option>
						<option value=\"SHA\" selected>SHA</option>";
					}
print "				</select></p>
					<p>->Privacy Protocol: <select name=\"snmp_privacy_protocol\">";
					if ($snmp_privacy_protocol=="AES"){
						print "<option value=\"AES\" selected>AES</option>
						<option value=\"DES\">DES</option>";
					}else if ($snmp_privacy_protocol=="DES"){
						print "<option value=\"AES\">AES</option>
						<option value=\"DES\" selected>DES</option>";
					}
print "				</select></p>
					<br>
					<b>SMART NOTIFICATION SETTINGS</b>
					<br>
					<b>SMART Parameter 1</b>
					<p>->Parameter Name: <input type=\"text\" name=\"paramter_1_name\" value=".$paramter_1_name."> ".$paramter_1_name_error."</p>
					<p>->Parameter Notification Threshold: <input type=\"text\" name=\"paramter_1_notification_threshold\" value=".$paramter_1_notification_threshold."> ".$paramter_1_notification_threshold_error."</p>
					<b>SMART Parameter 2</b>
					<p>-Parameter Name: <input type=\"text\" name=\"paramter_2_name\" value=".$paramter_2_name."> ".$paramter_2_name_error."</p>
					<p>->Parameter Notification Threshold: <input type=\"text\" name=\"paramter_2_notification_threshold\" value=".$paramter_2_notification_threshold."> ".$paramter_2_notification_threshold_error."</p>
					<b>SMART Parameter 3</b>
					<p>->Parameter Name: <input type=\"text\" name=\"paramter_3_name\" value=".$paramter_3_name."> ".$paramter_3_name_error."</p>
					<p>->Parameter Notification Threshold: <input type=\"text\" name=\"paramter_3_notification_threshold\" value=".$paramter_3_notification_threshold."> ".$paramter_3_notification_threshold_error."</p>
					<b>SMART Parameter 4</b>
					<p>->Parameter Name: <input type=\"text\" name=\"paramter_4_name\" value=".$paramter_4_name."> ".$paramter_4_name_error."</p>
					<p>->Parameter Notification Threshold: <input type=\"text\" name=\"paramter_4_notification_threshold\" value=".$paramter_4_notification_threshold."> ".$paramter_4_notification_threshold_error."</p>
					<b>SMART Parameter 5</b>
					<p>->Parameter Name: <input type=\"text\" name=\"paramter_5_name\" value=".$paramter_5_name."> ".$paramter_5_name_error."</p>
					<p>->Parameter Notification Threshold: <input type=\"text\" name=\"paramter_5_notification_threshold\" value=".$paramter_5_notification_threshold."> ".$paramter_5_notification_threshold_error."</p>
					<center><input type=\"submit\" name=\"submit_server_PDU\" value=\"Submit\" /></center>
				</form>
			</td>
		</tr>
	</table>
</fieldset>";
?>