data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_instance" "opensearch" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = "t2.medium"
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.os_profile.id
  vpc_security_group_ids      = [aws_security_group.os_http.id]
  subnet_id                   = data.aws_subnet.selected.id
  user_data                   = templatefile("${path.module}/userdata/opensearch.sh", { REGION = var.aws_region })

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
    Name = "Opensearch"
  }

  volume_tags = {
    Name = "Opensearch"
  }
}

resource "aws_instance" "victim" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.victim_profile.id
  vpc_security_group_ids      = [aws_security_group.victim_http.id]
  subnet_id                   = data.aws_subnet.selected.id
  user_data                   = file("${path.module}/userdata/victim.sh")

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