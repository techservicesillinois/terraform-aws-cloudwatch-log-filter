locals {
  function_name = var.function_name
  principal     = "logs.${data.aws_region.current.name}.amazonaws.com"
}

# Get current region.
data "aws_region" "current" {}

# Get lambda function name and ARN.
data "aws_lambda_function" "selected" {
  function_name = local.function_name
}

resource "aws_lambda_permission" "default" {
  count         = var.disable_subscription_filter ? 0 : 1
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.selected.function_name

  principal  = local.principal
  source_arn = aws_cloudwatch_log_group.default.arn
}

resource "aws_cloudwatch_log_subscription_filter" "default" {
  count          = var.disable_subscription_filter ? 0 : 1
  name           = "filter"
  log_group_name = aws_cloudwatch_log_group.default.name
  filter_pattern = var.filter_pattern

  # This is a workaround for a Terraform provider bug; see
  # https://github.com/terraform-providers/terraform-provider-aws/issues/5161.
  destination_arn = replace(data.aws_lambda_function.selected.arn, ":$LATEST", "")

  depends_on = [aws_lambda_permission.default]
}
