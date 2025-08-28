# Defining provider and region
provider "aws" {
  region = "eu-central-1"
}
#VPC

data "aws_vpc" "default" {
  default = true
}

#SUB
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# SG
data "aws_security_group" "default" {
  vpc_id = data.aws_vpc.default.id
  filter {
    name   = "group-name"
    values = ["default"]
  }
}

#RT
data "aws_route_table" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "association.main"
    values = ["true"]
  }
}

#IGW
data "aws_internet_gateway" "default" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

#KP
# data "aws_key_pair" "ssh_key" { if you want u can enter your already exsting key pair which you created on amason
#   key_name           = "ssh-key-servers"
#   include_public_key = true
# }
# Dynamically generate a new RSA key pair
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair using the generated public key
resource "aws_key_pair" "ssh_key" {
  key_name   = "ssh-key-servers"
  public_key = tls_private_key.ec2_key.public_key_openssh

  tags = {
    Name = "ssh-key-servers"
  }
}

# Save the private key to a local file
resource "local_file" "private_key" {
  content         = tls_private_key.ec2_key.private_key_pem
  filename        = "${path.module}/ssh-key-servers.pem"
  file_permission = "0600" # Secure permissions for the private key
}

#AMI's
# data "aws_ami" "amazon_linux" {
#   most_recent = true
#   owners      = ["amazon"]

#   filter {
#     name   = "name"
#     values = ["al2023-ami-*"]
#   }

#   filter {
#     name   = "architecture"
#     values = ["x86_64"]
#   }
# }

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}




#Ec2 with my keypair.pub
resource "aws_instance" "ec2_instances" {
  for_each = { for os, config in local.instance_configs : os => config if config.count > 0 }

  ami                         = each.value.ami
  instance_type               = each.value.instance_type
  subnet_id                   = data.aws_subnets.default.ids[0] # Using first available default subnet
  vpc_security_group_ids      = [data.aws_security_group.default.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.ssh_key.key_name # Associating the key pair

  tags = {
    Name = "${each.key}-instance"
    environment = "dev"
    role        = "web"
  }
}

#IP after apply
