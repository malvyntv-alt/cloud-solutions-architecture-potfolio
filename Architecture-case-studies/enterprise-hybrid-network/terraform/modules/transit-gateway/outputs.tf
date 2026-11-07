output "id" { value = aws_ec2_transit_gateway.this.id }

output "attachment_ids" { value = { for k, v in aws_ec2_transit_gateway_vpc_attachment.this : k => v.id } }

output "route_table_ids" { value = { for k, v in aws_ec2_transit_gateway_route_table.this : k => v.id } }
