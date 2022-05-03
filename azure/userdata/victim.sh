#!/bin/bash

# Install web services
apt update
apt install apache2 php -y

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

# Cleanup
rm /var/www/html/index.html
systemctl enable apache2
systemctl start apache2