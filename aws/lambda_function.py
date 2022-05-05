import subprocess
import boto3
import urllib.parse

def lambda_handler(event, context):
    # Get bucket name
    bucketName = event['Records'][0]['s3']['bucket']['name']

    # Get object path
    objectPath = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'], encoding='utf-8')
    file2hash = "/tmp/" + objectPath

    # Copy object to /tmp
    client = boto3.client('s3')
    client.download_file(
        Bucket = bucketName,
        Key = objectPath,
        Filename = "/tmp/" + objectPath
    )

    # Create MD5 hash
    md5sum = subprocess.check_output("md5sum /tmp/" + objectPath + " | awk '{print $1}'", shell=True).decode().strip("\n")

    # Create SHA1 hash
    sha1sum = subprocess.check_output("sha1sum /tmp/" + objectPath + " | awk '{print $1}'", shell=True).decode().strip("\n")

    # Create SHA256 hash
    sha256sum = subprocess.check_output("sha256sum /tmp/" + objectPath + " | awk '{print $1}'", shell=True).decode().strip("\n")

    # Add tags
    client.put_object_tagging(
        Bucket = bucketName,
        Key = objectPath,
        Tagging = {
            'TagSet': [
                {
                    'Key': 'MD5HASH',
                    'Value': md5sum
                },
                {
                    'Key': 'SHA1HASH',
                    'Value': sha1sum
                },
                {
                    'Key': 'SHA256HASH',
                    'Value': sha256sum
                }
            ]
        }
    )