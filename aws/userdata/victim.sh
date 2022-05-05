#!/bin/bash

# Install web services
yum update -y
amazon-linux-extras enable php7.4
yum install httpd php amazon-cloudwatch-agent -y
wget https://docs.aws.amazon.com/aws-sdk-php/v3/download/aws.zip -O /tmp/aws.zip
mkdir /var/www/html/aws-sdk
unzip -d /var/www/html/aws-sdk /tmp/aws.zip

# Write web content
cat << 'EOF' > /var/www/html/view-source.php
<html>
<head>
  <title>View Source</title>
</head>
<body>
<h1>View Source</h1>
<form action="/view-source.php" method="get">
  <label for="url">URL:</label>
  <input type="text" id="url" name="url"><br><br>
  <input type="submit" value="Submit">
</form>

<?php
if (!empty($_GET["url"])) {
  echo "<pre>";
  echo htmlentities(file_get_contents($_GET["url"]));
  echo "</pre>";
}
?>
</body>
</html>
EOF

cat << 'EOF' > /var/www/html/proof.php
<html>
<head>
<title>Evidence Upload</title>
</head>
<body>
<h1>Evidence Upload</h1>
<form action="proof.php" method="post" enctype="multipart/form-data">
  Select image to upload:
  <input type="file" name="fileToUpload" id="fileToUpload">
  <input type="submit" value="Upload Image" name="submit">
</form>

<?php
require '/var/www/html/aws-sdk/aws-autoloader.php'
?>

</body>
</html>
EOF

# Set up CloudWatch Agent
cat << 'EOF' > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "agent": {
    "run_as_user": "root",
    "logfile": "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/httpd/access_log",
            "log_group_name": "elastic/apache-access-log",
            "log_stream_name": "{instance_id}",
            "retention_in_days": 7
          },
          {
            "file_path": "/var/log/messages",
            "log_group_name": "elastic/syslog",
            "log_stream_name": "{instance_id}",
            "retention_in_days": 7
          }
        ]
      }
    }
  }
}
EOF

# Cleanup
rm /var/www/html/index.html
systemctl enable httpd
systemctl start httpd
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent