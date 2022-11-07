terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
  // access_key = var.access_key
  // secret_key = var.secret_key
}

locals {
  private_key_path = "~/.ssh/jenkins-terraform.pem"
}

# new vpc 
resource "aws_vpc" "jenkins" {
  cidr_block           = var.address_space
  enable_dns_hostnames = true

  tags = {
    name = "${var.prefix}-vpc-${var.region}"
    environment = var.environment
  }
}

resource "aws_subnet" "jenkins" {
  vpc_id     = aws_vpc.jenkins.id
  cidr_block = var.subnet_prefix

  tags = {
    name = "${var.prefix}-subnet"
  }
}

resource "aws_security_group" "jenkins" {
  name = "${var.prefix}-security-group"

  vpc_id = aws_vpc.jenkins.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
    Name = "${var.prefix}-security-group"
  }
}

resource "aws_internet_gateway" "jenkins" {
  vpc_id = aws_vpc.jenkins.id

  tags = {
    Name = "${var.prefix}-internet-gateway"
  }
}

resource "aws_route_table" "jenkins" {
  vpc_id = aws_vpc.jenkins.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.jenkins.id
  }
}

resource "aws_route_table_association" "jenkins" {
  subnet_id      = aws_subnet.jenkins.id
  route_table_id = aws_route_table.jenkins.id
}


data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

/* resource "aws_key_pair" "deployer" {
  key_name   = "terraform-key"
  public_key = var.public_key
} */

resource "aws_eip" "jenkins-master" {
  # instance = "${element(aws_instance.jenkins.*.id,count.index)}"
  instance = aws_instance.jenkins-master.id
  vpc   = true
}


resource "aws_eip_association" "jenkins-master" {
  instance_id   = aws_instance.jenkins-master.id
  allocation_id = aws_eip.jenkins-master.id
}

resource "aws_eip" "jenkins-slave" {
  # instance = "${element(aws_instance.jenkins.*.id,count.index)}"
  instance = aws_instance.jenkins-slave.id
  vpc   = true
}

resource "aws_eip_association" "jenkins-slave" {
  instance_id   = aws_instance.jenkins-slave.id
  allocation_id = aws_eip.jenkins-slave.id
}

# create an EC2 instance
resource "aws_instance" "jenkins-master" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.jenkins.id
  vpc_security_group_ids      = [aws_security_group.jenkins.id]
  key_name = "jenkins-terraform"
  tags = {
    Name = "jenkins-master + Terraform "
    }

  provisioner "remote-exec" {
   inline = ["echo 'wait until SSH is read'"]
   connection {
     type    = "ssh"
     user    = var.user
     private_key = file(local.private_key_path)
     host         = aws_instance.jenkins-master.public_ip
    }
   }

#kick off ansible to install the application
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.user} -i '${aws_instance.jenkins-master.public_ip},' --private-key ${local.private_key_path} /etc/ansible/playbook.yml"
   }
  }

resource "aws_instance" "jenkins-slave" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.jenkins.id
  vpc_security_group_ids      = [aws_security_group.jenkins.id]
  key_name = "jenkins-terraform"
  tags = {
    Name = "jenkins-slave + Terraform "
    }

  provisioner "remote-exec" {
   inline = ["echo 'wait until SSH is read'"]
   connection {
     type    = "ssh"
     user    = var.user
     private_key = file(local.private_key_path)
     host         = aws_instance.jenkins-slave.public_ip
    }
   }

#kick off ansible to install the application
  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ${var.user} -i '${aws_instance.jenkins-slave.public_ip},' --private-key ${local.private_key_path} /etc/ansible/jdk-playbook.yml"
   }
  }

output "instance_public_ip_master" {
  value = aws_instance.jenkins-master.public_ip
}

output "instance_public_ip_slave" {
  value = aws_instance.jenkins-slave.public_ip
}

