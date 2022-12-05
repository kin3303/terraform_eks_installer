
output "chart_values" {
  value =  concat([local.chart_values], var.additional_chart_values)
}
