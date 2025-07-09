include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::git@github.com:terraform-aws-modules/terraform-aws-lambda?ref=v7.13.0"
}

dependency "vpc" {
  config_path = values.vpc_path
  mock_outputs = {
    vpc_id             = "vpc-00000000"
    private_subnets    = ["subnet-00000000", "subnet-00000001"]
    vpc_cidr_block     = "10.0.0.0/16"
  }
}

dependency "rds" {
  config_path = values.rds_path
  mock_outputs = {
    db_instance_endpoint = "mock-db.cluster-xyz.us-east-1.rds.amazonaws.com"
    db_instance_port     = 3306
    db_instance_name     = "appdb"
  }
}

dependency "secrets_manager" {
  config_path = values.secrets_manager_path
  mock_outputs = {
    secret_arn = "arn:aws:secretsmanager:us-east-1:123456789012:secret:db-credentials-AbCdEf"
    secret_id  = "db-credentials"
  }
}

inputs = {
  function_name = values.function_name
  description   = try(values.description, "Serverless application function")
  handler       = try(values.handler, "index.handler")
  runtime       = try(values.runtime, "python3.11")
  timeout       = try(values.timeout, 30)
  memory_size   = try(values.memory_size, 256)

  source_path = try(values.source_path, null)
  s3_bucket   = try(values.s3_bucket, null)
  s3_key      = try(values.s3_key, null)
  
  create_package = try(values.create_package, values.source_path != null)
  
  vpc_subnet_ids         = dependency.vpc.outputs.private_subnets
  vpc_security_group_ids = [aws_security_group.lambda.id]
  
  environment_variables = merge(
    try(values.environment_variables, {}),
    {
      DB_HOST        = dependency.rds.outputs.db_instance_endpoint
      DB_PORT        = tostring(dependency.rds.outputs.db_instance_port)
      DB_NAME        = dependency.rds.outputs.db_instance_name
      SECRET_ARN     = dependency.secrets_manager.outputs.secret_arn
      AWS_REGION     = try(values.aws_region, "us-east-1")
    }
  )

  attach_network_policy = true
  
  dead_letter_target_arn = try(values.dead_letter_target_arn, null)
  
  reserved_concurrent_executions = try(values.reserved_concurrent_executions, -1)
  
  layers = try(values.layers, [])
  
  provisioned_concurrency_config = try(values.provisioned_concurrency_config, {})
  
  attach_policy_statements = true
  policy_statements = {
    secrets_manager = {
      effect = "Allow"
      actions = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      resources = [dependency.secrets_manager.outputs.secret_arn]
    }
    rds_connect = {
      effect = "Allow"
      actions = [
        "rds-db:connect"
      ]
      resources = ["*"]
    }
    cloudwatch_logs = {
      effect = "Allow"
      actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      resources = ["arn:aws:logs:*:*:*"]
    }
  }

  cloudwatch_logs_retention_in_days = try(values.cloudwatch_logs_retention_in_days, 14)
  
  tracing_config_mode = try(values.tracing_config_mode, "PassThrough")
  
  tags = try(values.tags, {})
}

resource "aws_security_group" "lambda" {
  name_prefix = "${values.function_name}-lambda-"
  vpc_id      = dependency.vpc.outputs.vpc_id
  description = "Security group for Lambda function"

  egress {
    description = "HTTPS to internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTP to internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "MySQL to RDS"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [dependency.vpc.outputs.vpc_cidr_block]
  }

  egress {
    description = "DNS"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    try(values.tags, {}),
    {
      Name = "${values.function_name}-lambda-sg"
    }
  )
}