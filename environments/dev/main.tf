terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "iam" {
  source        = "../../modules/iam"
  environment   = var.environment
  sns_topic_arn = module.notifications.sns_topic_arn
}

module "lambda" {
  source          = "../../modules/lambda"
  environment     = var.environment
  lambda_role_arn = module.iam.lambda_role_arn
}

module "monitoring" {
  source                  = "../../modules/monitoring"
  environment             = var.environment
  sns_topic_arn           = module.notifications.sns_topic_arn
  monitored_function_name = module.lambda.restart_function_name
}

module "notifications" {
  source             = "../../modules/notifications"
  environment        = var.environment
  slack_workspace_id = var.slack_workspace_id
  slack_channel_id   = var.slack_channel_id
}

module "dashboard" {
  source             = "../../modules/dashboard"
  environment        = var.environment
  status_lambda_arn  = module.lambda.status_function_arn
  status_lambda_name = module.lambda.status_function_name
}