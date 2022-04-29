#!/bin/bash

# Install web services
yum update -y
yum install httpd php amazon-cloudwatch-agent -y

# Write web content
cat << 'EOF' > /var/www/html/index.php
<html>
<head>
  <title>View Source</title>
</head>
<body>
<h1>View Source</h1>
<form action="/index.php" method="get">
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