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
        description  = "Keep last 10 images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["v"],
          countType     = "imageCountMoreThan",
          countNumber   = 10
        },
        action = {
          type = "expire"
        }
      }
    ]
  })

  repository_force_delete = true

  tags = local.tags
}

################################################################################
# ECR Registry
################################################################################

data "aws_iam_policy_document" "registry" {}

module "ecr_registry" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "2.3.1"

  create_repository = true

  # Registry Policy
  create_registry_policy = true
  registry_policy        = data.aws_iam_policy_document.registry.json

  # Registry Scanning Configuration
  manage_registry_scanning_configuration = true
  registry_scan_type                     = "ENHANCED"
  registry_scan_rules = [
    {
      scan_frequency = "SCAN_ON_PUSH"
      filter = []
    }
  ]

  tags = local.tags
}