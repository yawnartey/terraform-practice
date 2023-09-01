terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

#configuring aws access 
provider "aws" {
  region = "us-east-1"
  access_key = var.access_key
  secret_key = var.secret_key
}

#defining the key pair 
resource "aws_key_pair" "terraform_keypair" {
  key_name = "terraform-key-pair"
  public_key = file ("~/.ssh/id_rsa.pub")
}

#creating a vpc
resource "aws_vpc" "terraform-test-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "terraform-vpc"
  }
}

#creating internet gateway for my vpc above 
resource "aws_internet_gateway" "terraform-internet-gateway" {
  vpc_id = aws_vpc.terraform-test-vpc.id

  tags = {
    Name = "terraform-internet-gateway"
  }
}

#creating the route table
resource "aws_route_table" "terraform-route-table" {
  vpc_id = aws_vpc.terraform-test-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform-internet-gateway.id
  }

  tags = {
    Name = "terraform=route-table"
  }
}

#creating the subnet
resource "aws_subnet" "terraform-subnet" {
  vpc_id     = aws_vpc.terraform-test-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "terraform-test-subnet"
  }
}

#associate your subnet to your route table
resource "aws_route_table_association" "terraform-route-table-association" {
  subnet_id      = aws_subnet.terraform-subnet.id
  route_table_id = aws_route_table.terraform-route-table.id
}

#creating your security group
resource "aws_security_group" "terraform-allow-web-traffic" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.terraform-test-vpc.id

  ingress {
    description      = "HTTPS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-allow-web-traffic"
  }
}

#creating your network interface
resource "aws_network_interface" "terraform-test-nic" {
  subnet_id       = aws_subnet.terraform-subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.terraform-allow-web-traffic.id]

}

#creating and assigning your elastic ip 
resource "aws_eip" "terraform-test-eip" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.terraform-test-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.terraform-internet-gateway]
}

#creating the ubuntu server (instance) and launching your webserver
resource "aws_instance" "test-terraform" {
  ami           = "ami-053b0d53c279acc90"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"

  network_interface {
    network_interface_id = aws_network_interface.terraform-test-nic.id
    device_index         = 0
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install apache2 -y
    sudo systemctl start apache2
    sudo bash -c 'echo you have installed and started your webserver > /var/www/html/index.html'
    EOF

  tags = {
    Name = "test-terraform"
  }
}

output "instance_pub_ip_addr" {
  value =  aws_eip.terraform-test-eip.public_ip
}

output "ami" {
  value =  aws_instance.test-terraform.ami 
}

output "ami_id" {
  value = aws_instance.test-terraform.id
}

output "ami_private_ip" {
  value = aws_instance.test-terraform.private_ip
}

output "instance_state" {
  value = aws_instance.test-terraform.instance_state
}