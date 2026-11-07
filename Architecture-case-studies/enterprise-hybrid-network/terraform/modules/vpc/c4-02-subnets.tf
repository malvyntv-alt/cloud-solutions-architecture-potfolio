# Subnets. See docs/terraform-resource-map.md for the full resource index.

resource "aws_subnet" "workload" {
  for_each                = local.zones
  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.value
  cidr_block              = cidrsubnet(var.cidr, 8, tonumber(each.key) + 1)
  map_public_ip_on_launch = false
  tags                    = { Name = "${var.name}-workload-${each.key}" }
}

resource "aws_subnet" "attachment" {
  for_each                = local.zones
  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.value
  cidr_block              = cidrsubnet(cidrsubnet(var.cidr, 8, tonumber(each.key) + 251), 4, 0)
  map_public_ip_on_launch = false
  tags                    = { Name = "${var.name}-attachment-${each.key}" }
}
