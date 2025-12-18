terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

# --- 1. VPC INFRASTRUCTURE ---
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = "devops-project-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["ap-south-1a", "ap-south-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true # Saves money!
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/devops-practice-eks" = "shared"
  }
  
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
}

# --- 2. EKS CLUSTER ---
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "devops-practice-eks"
  cluster_version = "1.29"

  cluster_endpoint_public_access = true

  # Grants the creator Admin permissions automatically
  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    nodes = {
      min_size     = 1
      max_size     = 2
      desired_size = 1
      instance_types = ["t3.medium"]
    }
  }
}

# --- 3. KUBERNETES PROVIDER CONFIG ---
# This tells Terraform how to talk to the cluster it just created
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

# --- 4. DEPLOYMENT (Replaces deployment.yaml) ---
resource "kubernetes_deployment" "app" {
  metadata {
    name = "nginx-deployment"
    labels = {
      app = "nginx-app"
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "nginx-app"
      }
    }
    template {
      metadata {
        labels = {
          app = "nginx-app"
        }
      }
      spec {
        container {
          # REPLACE WITH YOUR DOCKER HUB IMAGE
          image = "YOUR_DOCKER_USER/devops-project:latest" 
          name  = "nginx-container"
          port {
            container_port = 80
          }
        }
      }
    }
  }
  
  # Ensure EKS is ready before deploying
  depends_on = [module.eks]
}

# --- 5. SERVICE (Replaces service.yaml) ---
resource "kubernetes_service" "app_service" {
  metadata {
    name = "nginx-service"
  }
  spec {
    selector = {
      app = kubernetes_deployment.app.spec.0.template.0.metadata.0.labels.app
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "LoadBalancer"
  }

  depends_on = [module.eks]
}

# --- 6. OUTPUTS ---
output "website_url" {
  description = "The URL to access the application"
  value       = kubernetes_service.app_service.status.0.load_balancer.0.ingress.0.hostname
}