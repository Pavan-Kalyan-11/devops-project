# 🚀 End-to-End DevOps Infrastructure & Deployment Project

## 📖 Project Overview
This project demonstrates a production-ready DevOps lifecycle. It provisions a Kubernetes (EKS) cluster on AWS using **Terraform** (Infrastructure as Code), containerizes a React/Nginx application using **Docker**, and automates the build and push process using **GitHub Actions**. It also includes a suite of Bash scripts for server maintenance and monitoring.

### 🏗 Architecture
**User Code** → **GitHub Repo** → **GitHub Actions (CI)** → **Docker Hub** → **AWS EKS (CD)**

## 🛠 Tech Stack
* **Cloud Provider:** AWS (VPC, EC2, EKS, S3, DynamoDB)
* **Infrastructure as Code:** Terraform (with Remote State Management)
* **Containerization:** Docker (Multi-stage builds)
* **Orchestration:** Kubernetes (EKS, Deployments, Services, RBAC)
* **CI/CD:** GitHub Actions
* **Scripting:** Bash (Monitoring, Backups, Log Cleanup)


## 📂 Project Structure

devops-project/
├── app/                        # The Application Code
│   ├── Dockerfile              # Multi-stage Docker build config
│   ├── nginx.conf              # Nginx server configuration
│   ├── package.json            # Node.js dependencies
│   └── public/                 # Static assets
├── terraform/                  # Infrastructure as Code
│   ├── main.tf                 # Resources (VPC, EKS, EC2, S3 Backend)
│   ├── variables.tf            # Configurable variables (Region, CIDR, etc.)
│   └── outputs.tf              # Outputs (Cluster Name, Endpoint)
├── k8s/                        # Kubernetes Manifests
│   ├── deployment.yaml         # App Deployment configuration
│   └── service.yaml            # LoadBalancer Service configuration
├── scripts/                    # Maintenance Scripts (Run on Bastion)
│   ├── monitor.sh              # CPU/Memory usage alerts
│   ├── backup.sh               # File backup utility
│   ├── uptime.sh               # Website health checker
│   └── ...
└── .github/
    └── workflows/
        └── docker-build.yml    # CI/CD Pipeline Configuration
        

# 🚀 Step-by-Step Implementation Guide

 # Phase 1: Manual AWS Setup (One-Time)
Terraform needs a remote backend to store its state file safely. You must create these manually in the AWS Console:

S3 Bucket: Create a bucket named your-unique-tfstate-bucket (Update this name in terraform/main.tf).

DynamoDB Table: Create a table named your-tfstate-lock-table with Partition Key LockID.


# Phase 2: Infrastructure Provisioning (Terraform)

Bash
cd terraform
Initialize and Apply:

Bash
terraform init
terraform plan
terraform apply --auto-approve
⏳ Wait ~15 minutes for the EKS cluster to be created.


# Phase 3: CI/CD Setup (GitHub Actions)
Push your code to GitHub.

Go to Settings → Secrets and variables → Actions.

Add the following Repository Secrets:

DOCKER_USERNAME: Your Docker Hub ID (e.g., pavankalyansdocker).
DOCKER_PASSWORD: Your Docker Hub Access Token.

Trigger the pipeline by making a commit. This will build and push the image pavankalyansdocker/my-nginx-app:latest to Docker Hub.

# Phase 4: Kubernetes Deployment


1.Connect to your new EKS Cluster:

Bash : aws eks update-kubeconfig --name devops-practice-eks --region ap-south-1

2.Deploy the application:

kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml


3.Verify the pods are running:

kubectl get pods

# Phase 5: Access the Application

Get the LoadBalancer URL:  kubectl get service nginx-service

Copy the EXTERNAL-IP (e.g., a456...us-east-1.elb.amazonaws.com) and paste it into your browser.


# 🖥 System Maintenance Scripts
This project includes Bash scripts for the Bastion Host (Jump Server) created by Terraform.

Get Bastion IP: Find the Public IP of the bastion instance in AWS EC2 Console.

Copy Scripts to Server: scp -i your-key.pem scripts/*.sh ec2-user@<BASTION_IP>:~

SSH into Server: ssh -i your-key.pem ec2-user@<BASTION_IP>

Run Scripts: Bash

chmod +x *.sh
./monitor.sh      # Check System Resources
./uptime.sh       # Check Website Status

## 🧹 Clean Up
To avoid AWS charges, destroy the resources when you are done:

Bash
cd terraform
terraform destroy --auto-approve

Note: Need to manually empty the S3 bucket before deleting.
