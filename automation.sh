#!/bin/sh

s3_bucket_name=upgrad-bhavesh
timestamp=$(date '+%d%m%Y-%H%M%S')
tar_file_name=bhavesh-httpd-logs-$timestamp.tar
log_path=/var/log/apache2
inventory_file=/var/www/html/inventory.html
cron_file_location=/etc/cron.d/automation

echo $tar_file_name

#udpate packages
echo "updating packages..."
sudo apt update -y

echo "---------------------------------------------------------"

#check if apache2 is installed
echo "checking if apache2 is installed"
#sudo apt show apache2
sudo dpkg -s apache2
apache2_installed=$?
echo "---------------------------------------------------------"

#if apache2 is not installed
if [ $apache2_installed -ne 0 ]
then
	echo "apache2 is not installed, will install now"
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
echo "checking if apache2 is enabled"
sudo systemctl is-enabled apache2
if [ $? -ne 0 ]
then
	echo "enabling the apache2"
	sudo systemctl enable apache2
fi

echo "---------------------------------------------------------"

#check if apache2 is active, else start it
echo "checking if apache2 is active"
sudo systemctl is-active apache2
if [ $? -ne 0 ]
then
	echo "starting the apache2 service"
	sudo systemctl start apache2
fi

echo "---------------------------------------------------------"

#create the tar file for *.log files under /tmp
echo "creating the tar file now"
tar -cvf /tmp/$tar_file_name $log_path/*.log

echo "---------------------------------------------------------"


#check if awscli is present
sudo dpkg -s awscli
aws_cli_installed=$?


if [ $aws_cli_installed -ne 0 ]
then
	echo "installing the aws cli..."
	sudo apt install awscli -y
	if [ $? -ne 0 ]
	then
		echo "Error installing the aws cli..."
	fi
fi

#upload the tar file into s3
echo "This is to upload the tar"
aws s3 cp /tmp/$tar_file_name s3://$s3_bucket_name/$tar_file_name


tar_file_size=$(ls -lh /tmp/$tar_file_name | awk '{print $5}')

# Inventory file relatd
if [ -e $inventory_file ]
then
	echo "inventory file is already present, hence will be updated..."
	echo "<p>httpd-logs &emsp;&emsp;&emsp;&emsp; $timestamp &emsp;&emsp;&emsp;&emsp; tar &emsp;&emsp;&emsp;&emsp; $tar_file_size </p>" >> $inventory_file
else
	echo "inventory file is not present. will create one now..."
	echo "<h3>Log &emsp;&emsp;&emsp;&emsp; Time created &emsp;&emsp;&emsp;&emsp; Type &emsp;&emsp;&emsp;&emsp; Size</h3>" > $inventory_file
	echo "<p>httpd-logs &emsp;&emsp;&emsp;&emsp; $timestamp &emsp;&emsp;&emsp;&emsp; tar &emsp;&emsp;&emsp;&emsp; $tar_file_size </p>" >> $inventory_file
fi

if [ ! -e $cron_file_location ]
then
	echo "cron job does not exist, adding one now..."
	echo "0 0 * * * root /root/Automation_Project/automation.sh" > $cron_file_location
fi