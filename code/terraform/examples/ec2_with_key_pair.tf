provider "aws" {
  region = "ap-south-2"
}

# Step 1. Create key pair(Private/Public)
#        a. Create private key using tls_private_key resource which is used by client
#        b. Store private key using local_file resource in local system
#        c. Create public key using aws_key_pair resource which is used by server. generally in aws it stores in console.
# Step 2. Create ec2 with existing public key which is created in Step 1

# Step 1. Create key pair(Private/Public)
# a. Create private key using tls_private_key resource which is used by client
resource "tls_private_key" "demo-private-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# b. Store private key using file resource in local system
resource "local_sensitive_file" "demo-private-key" {
  content = tls_private_key.demo-private-key.private_key_pem
  filename = "demo-private-key"
  file_permission = "0400" # Read access to user
}

# c. Create public key using aws_key_pair resource which is used by server. generally in aws it stores in console.
resource "aws_key_pair" "demo-public-key" {
    key_name = "demo-public-key"
    public_key = tls_private_key.demo-private-key.public_key_openssh
}

# Step 2. Create ec2 with existing public key which is created in Step 1
resource "aws_instance" "demo" {
  ami = "ami-04a5a6be1fa530f1c"
  instance_type = "t3.micro"
  key_name = aws_key_pair.demo-public-key.key_name
  security_groups = ["allow_ssh_sg"]
}

resource "aws_security_group" "allow_ssh_sg" {
  name        = "allow_ssh_sg"
  # Ingress - Inbound rules which allows input traffic
  ingress {
    description      = "ssh from sg"
    from_port        = 22 
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"] # Allow ipv4 from anywhere
  }
  # Egress - OutBound rules which allows outgoing traffic
  egress {
    from_port        = 0 # any port number
    to_port          = 0
    protocol         = "-1" # all protocols
    cidr_blocks      = ["0.0.0.0/0"] # Allow ipv4 from anywhere
    ipv6_cidr_blocks = ["::/0"] # Allow ipv6 from anywhere
  }

  tags = {
    Name = "allow_ssh_sg"
  }
}