# Route tables. See docs/terraform-resource-map.md for the full resource index.

resource "aws_route_table" "workload" {
  for_each = local.zones
  vpc_id   = aws_vpc.this.id
  tags     = { Name = "${var.name}-workload-${each.key}" }
}

resource "aws_route_table_association" "workload" {
  for_each       = local.zones
  subnet_id      = aws_subnet.workload[each.key].id
  route_table_id = aws_route_table.workload[each.key].id
}

resource "aws_route_table" "attachment" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name}-attachment-local-only" }
}

resource "aws_route_table_association" "attachment" {
  for_each       = local.zones
  subnet_id      = aws_subnet.attachment[each.key].id
  route_table_id = aws_route_table.attachment.id
}
