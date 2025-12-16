terraform {
required_version = ">= 1.5.0"

# -----------------------------------------------------------
  # COMMENT THIS WHOLE BLOCK OUT
  # -----------------------------------------------------------
  # backend "s3" {
  #   bucket         = "my-devops-tfstate-25"
  #   key            = "devops-eks/terraform.tfstate"
  #   region         = "ap-south-1"
  #   dynamodb_table = "my-devops-tfstate-lock-table"
  #   encrypt        = true
  # }
  # -----------------------------------------------------------

required_providers {
aws = {
source = "hashicorp/aws"
version = "~> 5.0"
}
}
}

provider "aws" {
region = var.aws_region
}

# Remote state resources (S3 + DynamoDB) ---

resource "aws_s3_bucket" "tf_state" {
bucket = "my-devops-tfstate-25"

tags = {
Name = "${var.project_name}-tfstate"
Environment = var.environment
}
}

resource "aws_s3_bucket_versioning" "tf_state_versioning" {
bucket = aws_s3_bucket.tf_state.id

versioning_configuration {
status = "Enabled"
}
}

resource "aws_dynamodb_table" "tf_lock" {
name = "my-devops-tfstate-lock-table"
billing_mode = "PAY_PER_REQUEST"
hash_key = "LockID"

attribute {
name = "LockID"
type = "S"
}

tags = {
Name = "${var.project_name}-tf-lock"
Environment = var.environment
}
}

# Networking (VPC, subnets, routing) ---

resource "aws_vpc" "my_vpc" {
cidr_block = var.vpc_cidr
enable_dns_support = true
enable_dns_hostnames = true

tags = {
Name = "${var.project_name}-vpc"
}
}

resource "aws_internet_gateway" "igw" {
vpc_id = aws_vpc.my_vpc.id

tags = {
Name = "${var.project_name}-igw"
}
}

resource "aws_subnet" "public" {
count = length(var.public_subnet_cidrs)
vpc_id = aws_vpc.my_vpc.id
cidr_block = var.public_subnet_cidrs[count.index]
map_public_ip_on_launch = true
availability_zone = element(var.azs, count.index)

tags = {
Name = "${var.project_name}-public-${count.index}"
}
}

resource "aws_subnet" "private" {
count = length(var.private_subnet_cidrs)
vpc_id = aws_vpc.my_vpc.id
cidr_block = var.private_subnet_cidrs[count.index]
availability_zone = element(var.azs, count.index)

tags = {
Name = "${var.project_name}-private-${count.index}"
}
}

resource "aws_route_table" "public" {
vpc_id = aws_vpc.my_vpc.id

route {
cidr_block = "0.0.0.0/0"
gateway_id = aws_internet_gateway.igw.id
}

tags = {
Name = "${var.project_name}-public-rt"
}
}

resource "aws_route_table_association" "public" {
count = length(aws_subnet.public)
subnet_id = aws_subnet.public[count.index].id
route_table_id = aws_route_table.public.id
}
# -------------------------------------------------------------------------
# NEW: NAT Gateway & Private Routing (The Professional Setup)
# -------------------------------------------------------------------------

# 1. Allocate a Static IP (Elastic IP) for the NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
  
  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

# 2. Create the NAT Gateway (Must live in a Public Subnet)
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id # Puts it in the first public subnet

  tags = {
    Name = "${var.project_name}-nat-gateway"
  }
  
  # Wait for the Internet Gateway to exist first
  depends_on = [aws_internet_gateway.igw]
}

# 3. Create a Route Table for Private Subnets (Traffic -> NAT Gateway)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

# 4. Connect ALL Private Subnets to this new Route Table
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# -------------------------------------------------------------------------

# Security group for bastion EC2

resource "aws_security_group" "bastion_sg" {
name = "${var.project_name}-bastion-sg"
description = "Allow SSH from your IP"
vpc_id = aws_vpc.my_vpc.id

ingress {
description = "SSH from my IP"
from_port = 22
to_port = 22
protocol = "tcp"
cidr_blocks = [var.my_ip_cidr]
}

egress {
from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"]
}

tags = {
Name = "${var.project_name}-bastion-sg"
}
}

# Bastion EC2 in public subnet
# 1. Add this Data Block (KEEP THIS - IT IS GOOD)
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# 2. COMMENT OUT THE ENTIRE KEY PAIR RESOURCE
# (This was failing because the public key string is invalid/incomplete)
# resource "aws_key_pair" "deployer" {
#   key_name   = "my-keypair"
#   public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQ..." 
# }

resource "aws_instance" "bastion" {
  # usage of the data source
  ami           = data.aws_ami.amazon_linux_2.id 
  
  instance_type = "t3.micro"                # 2 vCPUs
  subnet_id     = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  # 3. COMMENT OUT THIS LINE INSIDE THE INSTANCE
  # key_name = var.ec2_key_pair_name

  tags = {
    Name = "${var.project_name}-bastion"
  }
}

# EKS cluster using official module

module "eks" {
source = "terraform-aws-modules/eks/aws"
version = "~> 20.0"

cluster_name = "${var.project_name}-eks"
cluster_version = var.eks_version

cluster_endpoint_public_access = true

vpc_id = aws_vpc.my_vpc.id
subnet_ids = concat(
[for s in aws_subnet.public : s.id],
[for s in aws_subnet.private : s.id]
)

enable_cluster_creator_admin_permissions = true

#  EKS Managed Node Group (The Worker Nodes)

eks_managed_node_groups = {
main_node = {
instance_types = [var.node_instance_type]
min_size = 1
max_size = 2
desired_size = 2
capacity_type  = "ON_DEMAND"
}
}

tags = {
Environment = var.environment
Project = var.project_name
}
}