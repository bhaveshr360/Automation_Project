########################################################################################################################
# !/bin/bash
# Author: Bhavesh
# Description: The script does the following
#             - updates packages on the EC2 machine
#             - installs the apache web server if not present
#             - creates a service for the web server if not present, starts it if it is not running
#             - archives the log files present at /var/log/apache2 into tar files, uploads the tar files to the aws s3
#               bucket specified by the variable "s3_bucket"
#             - updates the size of the tar file and time stamp into the inventory file - /var/www/html/inventory.html
#                which acts as the index of the uploaded s3 files
#             - creates a cron job to periodically archive and upload the logs
########################################################################################################################

# variable declaration
s3_bucket_name=upgrad-bhavesh
timestamp=$(date '+%d%m%Y-%H%M%S')
tar_file_name=bhavesh-httpd-logs-$timestamp.tar
log_path=/var/log/apache2
inventory_file=/var/www/html/inventory.html
cron_file_location=/etc/cron.d/automation

#udpate packages
echo "updating packages..."
sudo apt update -y
echo "---------------------------------------------------------"

#check if apache2 is installed
echo "checking if apache2 is installed..."
sudo dpkg -s apache2
apache2_installed=$?
echo "---------------------------------------------------------"

#if apache2 is not installed
if [ $apache2_installed -ne 0 ]
then
	echo "apache2 is not installed, installing apache2..."
	#install apache 2
	sudo apt install apache2 -y
	err=$?
	if [ $err -ne 0 ]
	then
		echo "Unable to install apache2 exiting now. error code is : $err"
		exit 1
	fi
fi
echo "---------------------------------------------------------"

#Is apache2 enabled for systemctl, if not enable it
echo "checking if apache2 service is enabled..."
sudo systemctl is-enabled apache2
if [ $? -ne 0 ]
then
	echo "apache2 service is not enabled, enabling the apache2 service..."
	sudo systemctl enable apache2
fi
echo "---------------------------------------------------------"

#check if apache2 is active, else start it
echo "checking if apache2 service is active..."
sudo systemctl is-active apache2
if [ $? -ne 0 ]
then
	echo "apache2 service is not active, starting the apache2 service..."
	sudo systemctl start apache2
fi
echo "---------------------------------------------------------"

#create the tar file for *.log files under /tmp
echo "creating the tar file now..."
tar -cvf /tmp/$tar_file_name $log_path/*.log
echo "---------------------------------------------------------"

#check if awscli is present
echo "checking if aws cli is installed..."
sudo dpkg -s awscli
aws_cli_installed=$?
if [ $aws_cli_installed -ne 0 ]
then
	echo "aws cli is not installed, installing the aws cli..."
	sudo apt install awscli -y
	if [ $? -ne 0 ]
	then
		echo "Error installing the aws cli..."
		exit 1
	fi
fi
echo "---------------------------------------------------------"

#upload the tar file into s3
echo "uploading the archived tar file to s3 bucket..."
aws s3 cp /tmp/$tar_file_name s3://$s3_bucket_name/$tar_file_name
aws_upload_successful=$?

if [ $aws_upload_successful -ne 0 ]
then
  echo "error uploading to s3..."
  ext 1
else
  echo "successfully uploaded to the s3 bucket..."
fi
echo "---------------------------------------------------------"
