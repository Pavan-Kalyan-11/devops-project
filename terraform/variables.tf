# ---------variables.tf 

variable "project_name" {
  type        = string
  description = "Project prefix for all resources"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, stage, prod)"
  default     = "dev"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "ap-south-1"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public subnet CIDRs"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private subnet CIDRs"
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "azs" {
  type        = list(string)
  description = "Availability zones"
  default     = ["ap-south-1a", "ap-south-1b"]
}

variable "my_ip_cidr" {
  type        = string
  description = "Your public IP in CIDR (x.x.x.x/32) for SSH"
}

variable "ec2_ami_id" {
  type        = string
  description = "AMI ID for bastion EC2"
}

variable "ec2_instance_type" {
  type        = string
  description = "Instance type for bastion EC2"
  default     = "t3.micro"
}

variable "ec2_key_pair_name" {
  type        = string
  description = "Existing EC2 key pair name for SSH"
}

variable "eks_version" {
  type        = string
  description = "EKS Kubernetes version"
  default     = "1.29"
}

variable "node_instance_type" {
  type        = string
  description = "Instance type for EKS worker nodes"
  default     = "t3.medium"
}
