# Create the Virtual Private Cloud (VPC) for the grocery shop infrastructure
resource "aws_vpc" "grocery_shop_vpc" {
  cidr_block = "10.0.0.0/16"
  # Allows AWS to assign public DNS names to instances with public IPs
  enable_dns_hostnames = true

  tags = {
    Name = "grocery-shop-vpc"
  }
}


# Gateway to allow communication between the VPC and the internet
resource "aws_internet_gateway" "grocery_shop_igw" {
  vpc_id = aws_vpc.grocery_shop_vpc.id

  tags = { Name = "grocery-shop-igw" }
}


# First Public Subnet (AZ 1)
resource "aws_subnet" "grocery_shop_public_subnet_1" {
  vpc_id                  = aws_vpc.grocery_shop_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "grocery-shop-public-subnet-1"
  }
}

# Second Public Subnet (AZ 2) - Required for ALB
resource "aws_subnet" "grocery_shop_public_subnet_2" {
  vpc_id                  = aws_vpc.grocery_shop_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "grocery-shop-public-subnet-2"
  }
}


# Route table to direct public subnet traffic through the Internet Gateway
resource "aws_route_table" "grocery_shop_public_rt" {
  vpc_id = aws_vpc.grocery_shop_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.grocery_shop_igw.id
  }

  tags = {
    Name = "grocery-shop-public-rt"
  }
}


# Associate both public subnets with the route table
resource "aws_route_table_association" "grocery_shop_public_assoc_1" {
  subnet_id      = aws_subnet.grocery_shop_public_subnet_1.id
  route_table_id = aws_route_table.grocery_shop_public_rt.id
}

resource "aws_route_table_association" "grocery_shop_public_assoc_2" {
  subnet_id      = aws_subnet.grocery_shop_public_subnet_2.id
  route_table_id = aws_route_table.grocery_shop_public_rt.id
}


# Isolated private subnet for database workloads (no direct internet access)
resource "aws_subnet" "grocery_shop_private_subnet" {
  vpc_id            = aws_vpc.grocery_shop_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "grocery-shop-private-subnet-1"
  }
}

# Isolated private subnet 2 (AZ 1)
resource "aws_subnet" "grocery_shop_private_subnet_2" {
  vpc_id            = aws_vpc.grocery_shop_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "grocery-shop-private-subnet-2"
  }
}

