terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  tags       = merge({ "Name" = "${var.prefix}-vpc" }, var.tags)
}

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  tags       = merge({ "Name" = "${var.prefix}-public-subnet" }, var.tags)
  cidr_block = "10.0.1.0/24"
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  tags       = merge({ "Name" = "${var.prefix}-private-subnet" }, var.tags)
  cidr_block = "10.0.2.0/24"
}

resource "aws_internet_gateway" "gw" {
  tags   = merge({ "Name" = "${var.prefix}-internet-gw" }, var.tags)
  vpc_id = aws_vpc.main_vpc.id
}

resource "aws_route_table" "main_route" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = merge({ "Name" = "${var.prefix}-main-route" }, var.tags)
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.main_route.id
}

/**** **** **** **** **** **** **** **** **** **** **** ****
Create a separate EC2 Security Group to grant ingress and 
egress network traffic to the EC2 instance via the default
Subnet, Internet Gateway and Routing.
**** **** **** **** **** **** **** **** **** **** **** ****/

resource "aws_security_group" "interrupt_app" {
  name        = "interrupt_app"
  description = "Interrupt inbound traffic"
  vpc_id      = aws_vpc.main_vpc.id
  tags        = merge({ "Name" = "Interrupt App NSG" }, var.tags)
}

/**** **** **** **** **** **** **** **** **** **** **** ****
Explicitly allow all egress traffic for the scurity group. 
The CIDR should be changed to reflect the localized working
environment in the demo platform.
**** **** **** **** **** **** **** **** **** **** **** ****/

resource "aws_security_group_rule" "egress_allow_all" {
  description       = "Allow all outbound traffic."
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.interrupt_app.id
}

/**** **** **** **** **** **** **** **** **** **** **** ****
Explicitly accept SSH traffic.
**** **** **** **** **** **** **** **** **** **** **** ****/

resource "aws_security_group_rule" "allow_ssh" {
  description       = "SSH Connection"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.interrupt_app.id
}

/**** **** **** **** **** **** **** **** **** **** **** ****
Explicitly accept HTTP traffic.
**** **** **** **** **** **** **** **** **** **** **** ****/

resource "aws_security_group_rule" "allow_http" {
  description       = "HTTP Connection"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.interrupt_app.id
}

/**** **** **** **** **** **** **** **** **** **** **** ****
Define a private key pair to access the EC2 instance. Do not
expose the key outside fo the demo platform environment.
**** **** **** **** **** **** **** **** **** **** **** ****/

resource "tls_private_key" "main" {
  algorithm = "RSA"
}

locals {
  private_key_filename = "${var.prefix}-ssh-key"
}

resource "aws_key_pair" "main" {
  key_name   = local.private_key_filename
  public_key = tls_private_key.main.public_key_openssh
}

/**** **** **** **** **** **** **** **** **** **** **** ****
Saving the key locally as an optional use case. It is not 
necessary for the demo sequence and can be omitted.
**** **** **** **** **** **** **** **** **** **** **** ****/

resource "null_resource" "main" {
  provisioner "local-exec" {
    command = "echo \"${tls_private_key.main.private_key_pem}\" > ${var.prefix}-ssh-key.pem"
  }

  provisioner "local-exec" {
    command = "chmod 600 ${var.prefix}-ssh-key.pem"
  }
}

/**** **** **** **** **** **** **** **** **** **** **** ****
  Create a new instance of the latest Ubuntu on an EC2 instance,
  t2.micro node. We can find more options using the AWS command line:
 
   aws ec2 describe-images --owners 099720109477 \
     --filters "Name=name,Values=*hvm-ssd*bionic*18.04-amd64*" \
     --query 'sort_by(Images, &CreationDate)[].Name'
 
  aws ec2 describe-images --owners 099720109477 \
    --filters "Name=name,Values=*hvm-ssd*focal*20.04-amd64*" \
    --query 'sort_by(Images, &CreationDate)[].Name'

  Create a new instance of the latest SUSE on an EC2 instance,
  t2.micro node. We can find more options using the AWS command line.

  In this case we use ami-0cd60fd97301e4b49 and ami-0cd60fd97301e4b49
  to explicitly call out SUSE images that are Free Tier eligible.
 
   aws ec2 describe-images --owners 013907871322 \
     --filters "Name=image-id,Values=ami-0cd60fd97301e4b49" \
     --query 'sort_by(Images, &CreationDate)[].Name'
 
   aws ec2 describe-images --owners 013907871322 \
     --filters "Name=image-id,Values=ami-0cd60fd97301e4b49" \
     --query 'sort_by(Images, &CreationDate)[].Name'
 *** **** **** **** **** **** **** **** **** **** **** ****/

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    # values = ["suse-sles-15-sp6-v20240808-hvm-ssd-x86_64"] # SUSE
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
  # owners = ["013907871322"] # SUSE
}

resource "aws_instance" "app" {
  depends_on                  = [aws_internet_gateway.gw]
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.main.key_name
  vpc_security_group_ids      = [aws_security_group.interrupt_app.id]
  user_data_base64            = base64encode("${templatefile("${path.module}/templates/user-data.bash", { SDL_TOKEN = "${var.SDL_TOKEN}"})}")
  tags                        = merge({ "Name" = "${var.prefix}-ubuntu" }, var.tags)
  subnet_id                   = aws_subnet.private_subnet.id
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }
}
