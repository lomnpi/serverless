# Serverless application deployment using Terraform: hash-app

## Problem

Deploy an AWS Lambda Function that writes "*.sha256" files to a S3 bucket. The Lambda Function is triggered whenever ".json" or ".csv" files are created/uploaded to the S3 bucket. The lambda will then create a hash ".sha256" version of the file(s) in the S3 bucket.

## Solution

This solution contains a Terraform template 'hash-app-template.tf' and a 'src' folder containing a lambda function package.

## Deploy the solution

To run terraform, you need the following tools:

* Terraform CLI (0.14.9+) - [Install Terraform CLI](https://learn.hashicorp.com/tutorials/terraform/install-cli)
* AWS CLI - [Install AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
* AWS Account - [AWS Account](https://aws.amazon.com/free/)
* AWS Credentials - [Setup Access Keys](https://console.aws.amazon.com/iam/home?#/security_credentials)
* AWS Credentials with liberal permissions to CloudFormation, IAM, Lambda, KMS, and S3.

To build and deploy the application for the first time, run the following in your shell (should be in the /hash-app-terraform directory to run commands):

Initialize directory
```bash
terraform init
```

The template should be, so you may skip the 'terraform validate' and 'terraform plan' commands.

Apply Terraform configuration
```bash
terraform apply
```

This command will deploy the solution with these series of prompts:

* **var.aws_region**: The AWS Region to deploy to (e.g. us-east-1). Please enter a valid AWS Region.
* **var.hash_function_name**: The name of the Lambda function to create.
* **var.s3_bucket_name**: The name of the S3 Bucket to create.

Enter 'yes' to the Terraform prompt to perform changes.

## Clean Up

The S3 bucket has objects in it, a deletion policy, and versioning enabled. Start off by emptying and deleting the S3 bucket via the AWS Console.  

Delete AWS resources
```bash
terraform destroy
```

This command will remove the solution with these series of prompts:

* **var.aws_region**: Please enter a valid AWS Region for this prompt due to the regular expression on this variable.
* **var.hash_function_name**: Press Enter to skip.
* **var.s3_bucket_name**: Press Enter to skip.

Enter 'yes' to the Terraform prompt to destroy resources.
