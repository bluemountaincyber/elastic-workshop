data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_instance" "elastic" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = "t2.medium"
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.el_profile.id
  vpc_security_group_ids      = [aws_security_group.el_http.id]
  subnet_id                   = data.aws_subnet.selected.id
  user_data = templatefile("${path.module}/userdata/elastic.sh",
  { 
    REGION = var.aws_region, PASSWORD = var.elastic_password 
  })

  root_block_device {
    volume_size = 20
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "optional"
    instance_metadata_tags      = "disabled"
  }

  tags = {
    Name = "Elastic"
  }

  volume_tags = {
    Name = "Elastic"
  }
}

resource "aws_instance" "victim" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.victim_profile.id
  vpc_security_group_ids      = [aws_security_group.victim_http.id]
  subnet_id                   = data.aws_subnet.selected.id
  user_data                   = templatefile("${path.module}/userdata/victim.sh",
  {
    EVIDENCEBUCKET = aws_s3_bucket.el_evidence.id,
    REGION = var.aws_region
  })

  root_block_device {
    volume_size = 8
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "optional"
    instance_metadata_tags      = "disabled"
  }

  tags = {
    Name = "Victim"
  }

  volume_tags = {
    Name = "Victim"
  }
}

data "archive_file" "lambda_code" {
  type = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "el_function" {
  filename      = "${path.module}/lambda_function.zip"
  function_name = "hashevidence"
  role          = aws_iam_role.el_lambda.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"
  depends_on = [
    data.archive_file.lambda_code
  ]
}