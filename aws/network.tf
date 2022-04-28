data "aws_region" "current" {}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet" "selected" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = "${var.aws_region}a"
}

resource "aws_security_group" "os_http" {
  name        = "OpensearchHTTP"
  description = "Allow 9000/tcp inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP from world"
    from_port   = 5601
    to_port     = 5601
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "OpensearchHTTP"
  }
}

resource "aws_security_group" "victim_http" {
  name        = "VictimHTTP"
  description = "Allow 80/tcp inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP from world"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "VictimHTTP"
  }
}