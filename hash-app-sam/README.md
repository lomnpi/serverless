# hash-app

This solution contains source code and supporting files for a serverless application that you can deploy with the SAM CLI. It includes the following files and folders.

- src - Code for the application's lambda function.
- template.yaml - A template that defines the application's AWS resources.

The application uses several AWS resources, including Lambda function, S3 Bucket and KMS Key. These resources are defined in the `template.yaml` file in this project. You can update the template to add AWS resources through the same deployment process that updates the application code.


## Deploy the solution

The Serverless Application Model Command Line Interface (SAM CLI) is an extension of the AWS CLI that adds functionality for building and testing Lambda applications. 

To use the SAM CLI, you need the following tools.

* SAM CLI - [Install the SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html)
* [Python 3 installed](https://www.python.org/downloads/)
* AWS Credentials with liberal permissions to CloudFormation, IAM, Lambda, KMS, and S3.

To build and deploy the application for the first time, run the following in your shell (should be in the /hash-app-sam directory to run commands):

```bash
sam build
sam deploy --guided
```

The first command will build the source of the application. The second command will package and deploy the application to AWS, with a series of prompts:

* **Stack Name**: The name of the stack to deploy to CloudFormation. This should be unique to your account and region.
* **AWS Region**: The AWS region you want to deploy the app to.
* **Parameter BucketName**: The name of the S3 Bucket to create.
* **Parameter HashFunctionName**: THe name of the Lambda Function to create.
* **Confirm changes before deploy**: If set to yes, any change sets will be shown to you before execution for manual review. If set to no, the AWS SAM CLI will automatically deploy application changes.
* **Allow SAM CLI IAM role creation**: Create AWS IAM roles required for the AWS Lambda function included to access AWS services. By default, these are scoped down to minimum required permissions. 
* **Save arguments to samconfig.toml**: If set to yes, your choices will be saved to a configuration file inside the project, so that in the future you can just re-run `sam deploy` without parameters to deploy changes to the application.


## Cleanup

To delete the hash application that you deployed, use the SAM command below. Use the stack name you provided when deploying the application below:

```bash
sam delete --stack-name <stackname>
```

You can delete the config file manually or use the 'sam delete' command option below (default config file name is 'samconfig.toml'):

```bash
sam delete --stack-name <stackname> --config-file samconfig.toml
```

If the stack failed to delete, please use the AWS console to delete the S3 bucket manually, and retry stack deletion. The S3 Bucket has versioning enabled and a deletion policy if there are objects in it.

## Comment

Different possible solutions came to mind for this deployment, I believe this is the most efficient for the type of deployment in hand. I have implemented best measures for both security and scalability. I'm open to suggestions to more efficient solutions and things I could have done better. 
