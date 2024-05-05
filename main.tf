provider "aws" {
  region  = "us-west-1"
  profile = "default"
}

# ECR repository
resource "aws_ecr_repository" "example" {
  name = "example"
  tags = {
    "project" : "example-tf-continers"
  }
}

#  Using Terraforms null_resource allows us to implement a lifecycle on
# a resource and the triggers within it allows us to define a set of
# values that once updated will cause a resource to be replaced — in
# this case we want the resource to be replaced if there are any changes
# to our main python file or Dockerfile
resource "null_resource" "ecr_image" {
  triggers = {
    python_file = md5(file("./app.py"))
    docker_file = md5(file("./Dockerfile"))
  }
}
data "aws_ecr_image" "lambda_image" {
  depends_on      = [null_resource.ecr_image]
  repository_name = aws_ecr_repository.example.name
  image_tag       = "latest"
}


# Lambda
resource "aws_lambda_function" "example" {
  depends_on = [
    null_resource.ecr_image
  ]
  function_name = "example-lambda"
  #   architectures = ["arm64"]x86_64
  role         = aws_iam_role.lambda.arn
  timeout      = 180
  memory_size  = 10240
  image_uri    = "${aws_ecr_repository.example.repository_url}:latest"
  package_type = "Image"
}

resource "aws_cloudwatch_log_group" "example_service" {
  name              = "/aws/lambda/example_service"
  retention_in_days = 14
}

resource "aws_iam_role" "lambda" {
  name               = "example-lambda-role"
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
      "Action": "sts:AssumeRole",
      "Principal": {
         "Service": "lambda.amazonaws.com"
      },
       "Effect": "Allow"
   }
 ]
}
EOF
}

data "aws_iam_policy_document" "lambda" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect    = "Allow"
    resources = ["*"]
    sid       = "CreateCloudWatchLogs"
  }
}

resource "aws_iam_policy" "lambda" {
  name   = "example-lambda-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.lambda.json
}
