#AWS Chosen
#Managed Kubernetes (EKS)
#available/scalable (multi-AZ VPC, autoscaling node groups)
#Internet routing (public + private subnets, NAT gateway)
#

terraform { 

    backend "s3" {
    bucket         = "kfc-bucket-for-mo-to-enjoy"
    key            = "eks/terraform.tfstate"
    region         = "eu-west-2"
   }
  
  required_version = ">= 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" 
    }
  }
}

provider "aws" {
  region = var.region
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.region}a", "${var.region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.29"
  subnet_ids      = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  eks_managed_node_groups = {
    default = {
      instance_types = [var.node_instance_type]
      min_size       = 1
      max_size       = 3
      desired_size   = 2
    }
  }
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cloudwatch_log_group_retention_in_days = 7

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}
resource "aws_ecr_repository" "app" {
  name = "your-app-name"
image_scanning_configuration { 
  scan_on_push = true 
  } 
  tags = { 
    Environment = "dev" } 
    }

resource "aws_s3_bucket" "app_bucket" {
  bucket = "kfc-bucket-for-mo-to-enjoy"

  tags = {
    Environment = "dev"
  }
}
