output "vpc_id" { value = aws_vpc.this.id }

output "workload_subnet_ids" { value = { for k, v in aws_subnet.workload : k => v.id } }

output "attachment_subnet_ids" { value = [for v in aws_subnet.attachment : v.id] }

output "workload_route_table_ids" { value = { for k, v in aws_route_table.workload : k => v.id } }
