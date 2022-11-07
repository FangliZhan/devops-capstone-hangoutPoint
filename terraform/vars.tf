variable "region" {
  description = "region in aws"
  default     = "us-east-1"
}

variable "instance_type" {
  description = "instance type for the ec2 instances"
  default     = "t2.micro"
}

/* variable "access_key" {
  description = "access key for accessing aws"
}

variable "secret_key" {
  description = "secret key for accessing aws"
} */

variable "public_key" {
  description = "public key for access the ec2 instance"
}

variable "terraform-key" {
  description = "private key for ansible to access the instance"
  default = "~/.ssh/terraform-key"
}

variable "user" {
  description = "user to use for log into the machine"
  default = "ubuntu"
}

variable "environment" {
  description = "environment that the resources belong to"
  default = "dev"
}

variable "prefix" {
  description = "This prefix will be included in the name of most resources."
  default = "ansible-terraform-rosezhan"
}

variable "address_space" {
  description = "The address space that is used by the virtual network. You can supply more than one address space. Changing this forces a new resource to be created."
  default     = "10.0.0.0/16"
}

variable "subnet_prefix" {
  description = "The address prefix to use for the subnet."
  default     = "10.0.10.0/24"
}
