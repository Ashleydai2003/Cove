#
# eventbridge.tf
#
# EventBridge rule to trigger batch matcher Lambda every 3 hours
#

# EventBridge rule - runs every 3 hours
resource "aws_cloudwatch_event_rule" "batch_matcher_schedule" {
  name                = "cove-batch-matcher-schedule"
  description         = "Trigger batch matcher Lambda every 3 hours"
  schedule_expression = "rate(3 hours)"
  
  tags = merge(local.common_tags, {
    Name = "cove-batch-matcher-schedule"
  })
}

# EventBridge target - points to Lambda
resource "aws_cloudwatch_event_target" "batch_matcher_lambda" {
  rule      = aws_cloudwatch_event_rule.batch_matcher_schedule.name
  target_id = "BatchMatcherLambda"
  arn       = aws_lambda_function.batch_matcher.arn
  
  # Optional: Add input transformer to include metadata
  input_transformer {
    input_paths = {
      time = "$.time"
    }
    input_template = <<EOF
{
  "trigger": "eventbridge",
  "scheduledTime": <time>,
  "message": "Scheduled batch matching run"
}
EOF
  }
}

# Permission for EventBridge to invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.batch_matcher.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.batch_matcher_schedule.arn
}

# CloudWatch Log Group for the EventBridge rule (optional but recommended)
resource "aws_cloudwatch_log_group" "eventbridge_matcher_logs" {
  name              = "/aws/events/cove-batch-matcher"
  retention_in_days = 14
  
  tags = merge(local.common_tags, {
    Name = "cove-batch-matcher-eventbridge-logs"
  })
}

# CloudWatch Alarm - notify if matcher doesn't complete successfully
resource "aws_cloudwatch_metric_alarm" "batch_matcher_errors" {
  alarm_name          = "cove-batch-matcher-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "10800" # 3 hours
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Alert when batch matcher Lambda has errors"
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    FunctionName = aws_lambda_function.batch_matcher.function_name
  }
  
  # Optional: Add SNS topic for notifications
  # alarm_actions = [aws_sns_topic.alerts.arn]
  
  tags = merge(local.common_tags, {
    Name = "cove-batch-matcher-errors"
  })
}

# CloudWatch Alarm - notify if matcher is throttled
resource "aws_cloudwatch_metric_alarm" "batch_matcher_throttles" {
  alarm_name          = "cove-batch-matcher-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = "10800" # 3 hours
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Alert when batch matcher Lambda is throttled"
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    FunctionName = aws_lambda_function.batch_matcher.function_name
  }
  
  tags = merge(local.common_tags, {
    Name = "cove-batch-matcher-throttles"
  })
}

