resource "aws_vpc" "vpc01" {
  cidr_block = var.vpc_cidr
  tags = {
    name = "vpc01"
  }
}

#Public subnet and required resources
#################################################

resource "aws_internet_gateway" "intgw01" {
  vpc_id = aws_vpc.vpc01.id
  tags = {
    name = "intgw01"
  }
}
resource "aws_subnet" "public01" {
  vpc_id                  = aws_vpc.vpc01.id
  cidr_block              = var.public_subnet1
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true
  depends_on = [
    aws_internet_gateway.intgw01
  ]
  tags = {
    Name = "Public_Subnet01"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc01.id
  tags = {
    Name = "public_rtb"
  }
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.intgw01.id
}

resource "aws_route_table_association" "public01" {
  subnet_id      = aws_subnet.public01.id
  route_table_id = aws_route_table.public.id
}

#################################################