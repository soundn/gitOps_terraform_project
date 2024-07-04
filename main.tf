terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"

  backend "s3" {
    bucket = "kenbuck"
    key    = "aitech"
    region = "eu-north-1"
  }
}


provider "aws" {
  region = var.region
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "web_sg1" {
  name        = "web-sg1"
  description = "Security group for static website"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-sg"
  }
}

resource "aws_instance" "web" {
  ami                    = "ami-0705384c0b33c194c" # Ubuntu 24 AMI in eu-north-1
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.web_sg1.id]
  user_data              = <<-EOF
              #!/bin/bash
              
              # Deploy a Static Website on Ubuntu 24 with Nginx

              # Exit immediately if a command exits with a non-zero status
              set -e

              # 1. Update System Packages
              apt update

              # 2. Install Nginx
              apt install nginx -y

              # 3. Clone the Website Code
              git clone https://github.com/GerromeSieger/Static-Site.git

              # 4. Deploy the Website
              cp -r Static-Site/* /var/www/html

              # 5. Restart Nginx
              systemctl restart nginx

              echo "Static website deployment completed."
              EOF



  tags = {
    Name = "StaticWeb-terraform"
  }
}

resource "aws_instance" "nginx" {
  ami                    = "ami-0705384c0b33c194c" # Ubuntu 24 AMI in eu-north-1
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.web_sg1.id]
  user_data              = <<-EOF
              #!/bin/bash
              
              # Deploy a Static Website on Ubuntu 24 with Nginx

              # Exit immediately if a command exits with a non-zero status
              set -e

              # 1. Update System Packages
              apt update

              # 2. Install Nginx
              apt install nginx -y

              # 5. Restart Nginx
              systemctl restart nginx

              echo "Static website deployment completed."
              EOF

  tags = {
    Name = "nginx"
  }
}


output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "instance_backen_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.nginx.public_ip
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.web_sg1.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = data.aws_vpc.default.cidr_block
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = data.aws_vpc.default.id
}
