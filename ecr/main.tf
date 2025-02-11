provider "aws" {
  region = local.region
}

locals {
  region = "us-west-2"
  name   = "fryrank-app"

  account_id = data.aws_caller_identity.current.account_id

  tags = {
    Name       = local.name
    Example    = local.name
    Repository = "https://github.com/NickPriv/FryRankInfra"
  }
}

data "aws_caller_identity" "current" {}

################################################################################
# ECR Repository
################################################################################

module "ecr_disabled" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "2.3.1"

  create = false
}

module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "2.3.1"

  repository_name = local.name

  repository_read_write_access_arns = [data.aws_caller_identity.current.arn]
  create_lifecycle_policy           = true
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 2 images for frontend",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["fryrank-frontend"],
          countType     = "imageCountMoreThan",
          countNumber   = 2
        },
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2,
        description  = "Keep last 2 images for backend",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["fryrank-backend"],
          countType     = "imageCountMoreThan",
          countNumber   = 2
        },
        action = {
          type = "expire"
        }
      }
    ]
  })

  tags = local.tags
}

################################################################################
# ECR Registry
################################################################################

module "ecr_registry" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "2.3.1"

  repository_name = local.name

  create_repository = false
  create_lifecycle_policy = false

  # Registry Policy
  create_registry_policy = false

  # Repository Policy
  create_repository_policy = false
  repository_policy = jsonencode({})

  # Registry Scanning Configuration
  manage_registry_scanning_configuration = true
  registry_scan_type                     = "ENHANCED"
  registry_scan_rules = [
    {
      scan_frequency = "SCAN_ON_PUSH"
      filter = [
        {
          filter      = "*"
          filter_type = "WILDCARD"
        }
      ]
    }
  ]

  tags = local.tags
}