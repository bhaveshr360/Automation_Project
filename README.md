# Automation_Project
This project installs apache2 web server, adds it as a service and creates a cron job to archive the logs on a daily basis and upload them to the specified s3 bucket.

Following variables can be updated to configure the script

s3_bucket_name - The s3 bucket name to be used

tar_file_path - path on the local system when the tar files should reside

tar_file_name - the name of the tar file that will be uploaded to s3, defaults to bhavesh-httpd-logs-<timestamp>.tar

log_path=/var/log/apache2 - the path where the apache2 logs reside

inventory_file_name=/var/www/html/inventory.html - the path and name of the inventory file that is used to display all the tar files present

cron_file_location=/etc/cron.d/automation - location of the cron job file
