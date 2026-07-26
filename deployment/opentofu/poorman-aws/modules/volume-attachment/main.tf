data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/src/handler.py"
  output_path = "${path.root}/.terraform/${var.name}-volume-attachment.zip"
}

resource "aws_iam_role" "lambda" {
  name = "${var.name}-volume-attachment"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "lambda" {
  name = "attach-persistent-volume"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "InspectCompute"
        Effect   = "Allow"
        Action   = ["ec2:DescribeInstances", "ec2:DescribeVolumes"]
        Resource = "*"
      },
      {
        Sid    = "AttachDataVolume"
        Effect = "Allow"
        Action = [
          "ec2:AttachVolume",
          "ec2:CreateTags",
          "ec2:DetachVolume",
        ]
        Resource = [
          var.data_volume_arn,
          "arn:${data.aws_partition.current.partition}:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:instance/*",
        ]
      },
      {
        Sid      = "ControlLaunchLifecycle"
        Effect   = "Allow"
        Action   = ["autoscaling:CompleteLifecycleAction", "autoscaling:RecordLifecycleActionHeartbeat"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "autoscaling:ResourceTag/Name" = var.name
          }
        }
      },
      {
        Sid      = "WriteFunctionLogs"
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "${aws_cloudwatch_log_group.this.arn}:*"
      },
    ]
  })
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.name}-volume-attachment"
  retention_in_days = 7
  tags              = var.tags
}

resource "aws_lambda_function" "this" {
  function_name = "${var.name}-volume-attachment"
  description   = "Attach the persistent Golden Mammoth EBS volume during ASG launch"
  role          = aws_iam_role.lambda.arn
  runtime       = "python3.13"
  handler       = "handler.handler"
  timeout       = 600
  memory_size   = 128

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  environment {
    variables = {
      ASG_NAME    = var.autoscaling_group_name
      DEVICE_NAME = var.data_device_name
      VOLUME_ID   = var.data_volume_id
    }
  }

  tags       = var.tags
  depends_on = [aws_iam_role_policy.lambda]
}

resource "aws_cloudwatch_event_rule" "launch" {
  name        = "${var.name}-attach-volume"
  description = "Capture Golden Mammoth ASG launch lifecycle actions"

  event_pattern = jsonencode({
    source      = ["aws.autoscaling"]
    detail-type = ["EC2 Instance-launch Lifecycle Action"]
    detail = {
      AutoScalingGroupName = [var.autoscaling_group_name]
      LifecycleHookName    = ["attach-persistent-volume"]
    }
  })
  tags = var.tags
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule = aws_cloudwatch_event_rule.launch.name
  arn  = aws_lambda_function.this.arn

  retry_policy {
    maximum_event_age_in_seconds = 900
    maximum_retry_attempts       = 8
  }
}

resource "aws_lambda_permission" "events" {
  statement_id  = "AllowEventBridgeLaunchLifecycle"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.launch.arn
}
