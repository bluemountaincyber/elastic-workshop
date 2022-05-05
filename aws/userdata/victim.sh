#!/bin/bash

# Install web services
yum update -y
amazon-linux-extras enable php7.4
yum install httpd php php-mbstring php-xml amazon-cloudwatch-agent -y
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
  <style>
    table, th, td {  
      border: 1px solid black;  
      border-collapse: collapse;
    }
  </style>
  </head>
  <body>
    <h1>Evidence Upload</h1>
    <form action="proof.php" method="post" enctype="multipart/form-data">  Select image to upload:
    <input type="file" name="fileToUpload" id="fileToUpload">  
    <input type="submit" value="Upload Image" name="submit">
    </form>
  <table>
    <tr>
      <th>File Name</th>
      <th>MD5 Hash</th>    
      <th>SHA1 Hash</th>    
      <th>SHA256 Hash</th>  
    </tr>

<?php
require '/var/www/html/aws-sdk/aws-autoloader.php';
use Aws\S3\S3Client;use Aws\Exception\AwsException;
$s3Client = new S3Client([
    'region' => '${REGION}',
    'version' => '2006-03-01'
]);
// Get S3 data and add to table
$result = $s3Client->listObjects([
  'Bucket' => '${EVIDENCEBUCKET}'
]);
foreach ($result->get("Contents") as $object) {
  $objectKey = $object["Key"];
  echo "<tr><td>$objectKey</td>";

  // Get MD5 Hash
  $result = $s3Client->getObjectTagging([
    'Bucket' => '${EVIDENCEBUCKET}',
    'Key' => $objectKey
  ]);
  foreach ($result->get("TagSet") as $tag) {
    if ($tag["Key"] == "MD5HASH") {
      $md5Hash = $tag["Value"];
    }
    if ($tag["Key"] == "SHA1HASH") {
      $sha1Hash = $tag["Value"];
    }
    if ($tag["Key"] == "SHA256HASH") {
      $sha256Hash = $tag["Value"];
    }
  }
  echo "<td>$md5Hash</td>";
  echo "<td>$sha1Hash</td>";
  echo "<td>$sha256Hash</td></tr>";
}
echo "</table>";
if(isset($_POST["submit"])) {

  $result = $s3Client->putObject([
    'Bucket' => '${EVIDENCEBUCKET}',
    'Key' => $_FILES["fileToUpload"]["name"],
    'Body' => file_get_contents($_FILES["fileToUpload"]["tmp_name"])
  ]);

  if ($result) {
    $output = "The file ". htmlspecialchars( basename( $_FILES["fileToUpload"]["name"])). " has been uploaded.";
  } else {
    $output = "Sorry, there was an error uploading your file.";
  }
  sleep(10);
  header("Refresh:0");
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