# To prevent namespace collisions.
resource "random_string" "rand" {
  length  = 24
  special = false
  upper   = false
}

locals {
  namespace = substr(join("-", [var.name, random_string.rand.result]), 0, 24)
}

locals {
  projects = ["plan", "apply"]
}

resource "aws_codebuild_project" "project" {
  count        = length(local.projects)
  name         = "${local.namespace}-${local.projects[count.index]}"
  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  # HashiCorp maintains this image and creates a tagged release for
  #  each version of Terraform. This image is basically Alpine Linux with the Terraform
  #  binary baked in. We are using it here to obviate the need to download Terraform at
  #  runtime (a potentially slow operation).
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "hashicorp/terraform:${var.terraform_version}"
    type         = "LINUX_CONTAINER"
  }

  source {
    type      = "NO_SOURCE"
    buildspec = file("${path.module}/templates/buildspec_${local.projects[count.index]}.yml")
  }
}


locals {
  # Template for the backend configuration.
  backend = templatefile("${path.module}/templates/backend.json",
  { config : var.s3_backend_config, name : local.namespace })

  # Declare the default environment variables.
  # The first two are Terraform settings, and the next three are used by the code in our buildspec.
  default_environment = {
    TF_IN_AUTOMATION  = "1"
    TF_INPUT          = "0"
    CONFIRM_DESTROY   = "0"
    WORKING_DIRECTORY = var.working_directory
    BACKEND           = local.backend # A JSON-encoded string that configures the remote backend.
  }

  # Merges default environment variables with user-supplied values and convert to json format.
  environment = jsonencode([for k, v in merge(local.default_environment,
  var.environment) : { name : k, value : v, type : "PLAINTEXT" }])
}

# An S3 bucket that is used to cache artifacts between build stages (it’s just part of how CodePipeline works).
resource "aws_s3_bucket" "codepipeline" {
  bucket        = "${local.namespace}-codepipeline"
  acl           = "private"
  force_destroy = true
}

# The Approve stage uses an SNS topic to send notifications when manual
#   approval is required (currently these notifications go nowhere, but SNS could be con-
#   figured to send notifications to a designated target).
resource "aws_sns_topic" "codepipeline" {
  name = "${local.namespace}-codepipeline"
}

# a CodeStarConnections connection manages access to GitHub (so you do not need to use a private access token).
resource "aws_codestarconnections_connection" "github" {
  name          = "${local.namespace}-github"
  provider_type = "GitHub"
}


resource "aws_codepipeline" "codepipeline" {

  name     = "${local.namespace}-pipeline"
  role_arn = aws_iam_role.codepipeline.arn
  artifact_store {
    location = aws_s3_bucket.codepipeline.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        FullRepositoryId = var.vcs_repo.identifier
        BranchName       = var.vcs_repo.branch
        # Source fetches code from GitHub using CodeStar.
        ConnectionArn = aws_codestarconnections_connection.github.arn
      }
    }
  }


  stage {
    name = "Plan"
    action {
      name            = "Plan"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version         = "1"
      configuration = {
        # Plan uses the zero-index CodeBuild project defined earlier --> project[0] == "plan".
        ProjectName          = aws_codebuild_project.project[0].name
        EnvironmentVariables = local.environment
      }
    }
  }


  dynamic "stage" {
    # Dynamic block with a feature flag
    # if auto_apply variable is true, then it's already approved and we don't need to created this block("[]"),
    #   else, if auto_apply is flase (default value), then create this block ("[1]") to generate a stage that
    #       ask a human to approve the plan to be able to move to the next stage (apply stage).
    for_each = var.auto_apply ? [] : [1]
    content {
      name = "Approve"

      action {
        name     = "Approve"
        category = "Approval"
        owner    = "AWS"
        provider = "Manual"
        version  = "1"

        configuration = {
          CustomData      = "Please review output of plan and approve"
          NotificationArn = aws_sns_topic.codepipeline.arn
        }

      }
    }
  }


  stage {
    name = "Apply"

    action {
      name            = "Apply"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        # Plan uses the zero-index CodeBuild project defined earlier --> project[1] == "apply"
        ProjectName          = aws_codebuild_project.project[1].name
        EnvironmentVariables = local.environment
      }
    }
  }
}
