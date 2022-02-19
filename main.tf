# Deploy an s3 backend that will be used by CodePipeline.
module "s3backend" {
  source         = "terraform-in-action/s3backend/aws"
  principal_arns = [module.codepipeline.deployment_role_arn]
}

# Deploy a CI/CD pipeline for Terraform.
module "codepipeline" {
  source   = "./modules/codepipeline"
  name     = "terraform-ci-cd"
  vcs_repo = var.vcs_repo

  environment = {
    CONFIRM_DESTROY = 0 # zero will allow the pipeline to issue "terraform apply" command
  }

  deployment_policy = file("./policies/ec2.json")
  s3_backend_config = module.s3backend.config
}
