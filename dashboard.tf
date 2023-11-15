resource "aws_cloudwatch_dashboard" "demo-dashboard" {
  dashboard_name = "NAT-Gateway-traffic-inspection-${module.vpc.natgw_ids[0]}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 3
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/NATGateway", "BytesOutToDestination", "NatGatewayId", "${module.vpc.natgw_ids[0]}", { "id": "e1" }],
            ["AWS/NATGateway", "BytesOutToSource", "NatGatewayId", "${module.vpc.natgw_ids[0]}", { "id": "e2" }],
            [{ "expression": "SUM([e1, e2])", "label": "Total Bytes Out", "id": "e3" }]
          ]
          period = 300
          stat   = "Sum"
          region = local.region
          title  = "Total Bytes Out (Destination + Source)"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            [
              "AWS/NATGateway",
              "BytesOutToDestination",
              "NatGatewayId",
              "${module.vpc.natgw_ids[0]}"
            ]
          ]
          period = 300
          stat   = "Sum"
          region = local.region
          title  = "${module.vpc.natgw_ids[0]} - Bytes Out To Destination"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            [
              "AWS/NATGateway",
              "BytesOutToSource",
              "NatGatewayId",
              "${module.vpc.natgw_ids[0]}"
            ]
          ]
          period = 300
          stat   = "Sum"
          region = local.region
          title  = "${module.vpc.natgw_ids[0]} - Bytes Out To Source"
        }
      }
    ]
  })
}
