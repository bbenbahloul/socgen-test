terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "tech-test-tfstate-bbenbahloul"
    key    = "tech-test/terraform.tfstate"
    region = "eu-west-3"                     
  }
}

# ==========================================
# 1. VARIABLES & DYNAMIC DATA
# ==========================================
variable "aws_region" {
  description = "The AWS region to deploy the infrastructure"
  type        = string
  default     = "eu-west-3"
}

provider "aws" {
  region = var.aws_region
}

# Fetch the current AWS account ID dynamically
data "aws_caller_identity" "current" {}

# Fetch the current region dynamically (based on the provider)
data "aws_region" "current" {}


# ==========================================
# 2. IAM ROLE FOR ECR ACCESS
# ==========================================
resource "aws_iam_role" "apprunner_role" {
  name = "apprunner-ecr-access-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "build.apprunner.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "apprunner_ecr_policy" {
  role       = aws_iam_role.apprunner_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}


# ==========================================
# 3. AUTO-SCALING CONFIGURATION
# ==========================================
resource "aws_apprunner_auto_scaling_configuration_version" "load_scaling" {
  auto_scaling_configuration_name = "tech-test-scaling"
  max_concurrency                 = 20
  min_size                        = 1 
  max_size                        = 4 
}


# ==========================================
# 4. BACKEND APP RUNNER SERVICE
# ==========================================
resource "aws_apprunner_service" "backend" {
  service_name = "tech-test-backend"

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_role.arn
    }
    
    image_repository {
      image_configuration { port = "8080" }
      
      # DYNAMIC REGION AND ACCOUNT ID INJECTED HERE
      image_identifier      = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/tech-test-backend:latest"
      image_repository_type = "ECR"
    }
    
    auto_deployments_enabled = true 
  }

  instance_configuration {
    cpu    = "1024" 
    memory = "2048" 
  }

  auto_scaling_configuration_arn = aws_apprunner_auto_scaling_configuration_version.load_scaling.arn
  
  health_check_configuration {
    protocol            = "HTTP"
    path                = "/health"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 1
    unhealthy_threshold = 5
  }
}


# ==========================================
# 5. FRONTEND APP RUNNER SERVICE
# ==========================================
resource "aws_apprunner_service" "frontend" {
  service_name = "tech-test-frontend"

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_role.arn
    }
    
    image_repository {
      image_configuration { port = "80" }
      
      # DYNAMIC REGION AND ACCOUNT ID INJECTED HERE
      image_identifier      = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/tech-test-frontend:latest"
      image_repository_type = "ECR"
    }
    
    auto_deployments_enabled = true 
  }

  instance_configuration {
    cpu    = "1024" 
    memory = "2048" 
  }

  auto_scaling_configuration_arn = aws_apprunner_auto_scaling_configuration_version.load_scaling.arn
  
  health_check_configuration {
    protocol            = "HTTP"
    path                = "/"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 1
    unhealthy_threshold = 5
  }
}


# ==========================================
# 6. OUTPUTS
# ==========================================
output "backend_url" {
  value       = "https://${aws_apprunner_service.backend.service_url}"
  description = "The public URL of your Backend application"
}

output "frontend_url" {
  value       = "https://${aws_apprunner_service.frontend.service_url}"
  description = "The public URL of your Frontend application"
}