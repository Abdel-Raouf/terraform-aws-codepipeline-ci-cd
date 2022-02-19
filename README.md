<!-- BEGIN_TF_DOCS -->
# Developing A Terraform CI/CD for AWS.

## **Using** the following *technologies*:

### [AWS codePipeline](https://aws.amazon.com/codepipeline/):

- An AWS fully managed continues delivery service.
- it's used in our project to handle Two Stages:
    - Source Stage --> "This stage handles the download of source code from the Github Repository."
    - Approve Stage --> "This stage handles the approve or rejection of the changes made in the commit      pushed to the Github Repository."

### [AWS codeBuild](https://aws.amazon.com/codebuild/):

- An AWS fully managed continues integration service.
- it's used in our project to handle Two Stages:
    - Plan Stage --> "This stage handles plan generation for our terraform code."
    - Apply Stage --> "This stage handles the creation of the AWS infra-structure."

### [AWS CodeStar Connections](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-codestarconnections-connection.html):

- To manage access to GitHub Repository (so we do not need to use a private access token).


### This is the Full AWS CodePipeline Successfully Deployed:
![CodeStar Connection](https://github.com/Abdel-Raouf/terraform-aws-codepipeline-ci-cd/blob/master/images/code_star_conn_image.png)
![Source Stage](https://github.com/Abdel-Raouf/terraform-aws-codepipeline-ci-cd/blob/master/images/source_stage_image.png)
![Plan Stage](https://github.com/Abdel-Raouf/terraform-aws-codepipeline-ci-cd/blob/master/images/plan_stage_image.png)
![Approve and Apply stages](https://github.com/Abdel-Raouf/terraform-aws-codepipeline-ci-cd/blob/master/images/approve_and_apply_stage_image.png)


### This is the Deployed EC2 instance using CodePipeline:

- [This the Github Repo that contains the terraform code we used for the pipeline to deploy an ec2 instance](https://github.com/Abdel-Raouf/terraform-aws-ec2-deployment) 

![Deployed EC2 instance](https://github.com/Abdel-Raouf/terraform-aws-codepipeline-ci-cd/blob/master/images/ec2_deployed_through_pipeline.png)


## Requirements

No requirements.

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_codepipeline"></a> [codepipeline](#module\_codepipeline) | ./modules/codepipeline | n/a |
| <a name="module_s3backend"></a> [s3backend](#module\_s3backend) | terraform-in-action/s3backend/aws | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_vcs_repo"></a> [vcs\_repo](#input\_vcs\_repo) | n/a | `object({ identifier = string, branch = string })` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->

