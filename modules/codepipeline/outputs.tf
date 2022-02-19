# The s3backend module uses this output to authorize CodeBuild to read objects from the
#   S3 bucket storing Terraform state.
output "deployment_role_arn" {
  value = aws_iam_role.codebuild.arn
}
