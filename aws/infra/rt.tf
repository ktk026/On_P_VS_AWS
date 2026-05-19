# 퍼블릭 라우트 테이블
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "app-public-rt"
  }
}

resource "aws_route_table_association" "public_2a" {
  subnet_id      = aws_subnet.public_2a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2c" {
  subnet_id      = aws_subnet.public_2c.id
  route_table_id = aws_route_table.public.id
}



# 프라이빗 라우트 테이블
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "app-private-rt"
  }
}

resource "aws_route_table_association" "private_2a" {
  subnet_id      = aws_subnet.private_2a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2c" {
  subnet_id      = aws_subnet.private_2c.id
  route_table_id = aws_route_table.private.id
}



# DB 서브넷 라우트 테이블
resource "aws_route_table" "db" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "app-db-rt"
  }
}

resource "aws_route_table_association" "db_2a" {
  subnet_id      = aws_subnet.db_2a.id
  route_table_id = aws_route_table.db.id
}

resource "aws_route_table_association" "db_2c" {
  subnet_id      = aws_subnet.db_2c.id
  route_table_id = aws_route_table.db.id
}
