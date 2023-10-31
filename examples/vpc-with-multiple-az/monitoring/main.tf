resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.resource_name_prefix}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        "height" : 6,
        "width" : 6,
        "y" : 0,
        "x" : 0,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            [
              {
                "expression" : "SELECT AVG(graphdb_cpu_load) FROM \"${var.resource_name_prefix}-graphdb\" GROUP BY host",
                "id" : "q1",
                "label" : "CPU",
                "region" : var.aws_region,
                "stat" : "Average"
              }
            ]
          ],
          "region" : var.aws_region,
          "stacked" : false,
          "view" : "timeSeries",
          "period" : 300,
          "stat" : "Average"
        }
      }
    ]
  })
}
