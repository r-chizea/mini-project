terraform {
    required_providers {
      aws = {
        source = "hashicorp/aws"
      }
    }
}

provider "aws" {
  region = "eu-west-2"
}

resource "aws_vpc" "project_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    name = "project_vpc"
  }
}

resource "aws_subnet" "project_subnet_1" {
  vpc_id = aws_vpc.project_vpc.id
  cidr_block = "10.0.0.0/22"
  tags = {
      name = "project_subnet_1"
  }
}

resource "aws_subnet" "project_subnet_2" {
  vpc_id = aws_vpc.project_vpc.id
  cidr_block = "10.0.4.0/22"
  tags = {
      name = "project_subnet_1"
  }
}

resource "aws_subnet" "project_subnet_3" {
  vpc_id = aws_vpc.project_vpc.id
  cidr_block = "10.0.8.0/22"
  tags = {
      name = "project_subnet_3"
  }
}

resource "aws_security_group" "ci_sg" {
  name = "ci_sg"
  description = "security group for ci server"
  vpc_id = aws_vpc.project_vpc.id

  ingress {
    description = "Inbound SSH connections"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = [ "::/0" ]
  }

  ingress {
    description = "Inbound HTTP connections"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = [ "::/0" ]
  }

  ingress {
    description = "Inbound SQL connections"
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = [ "::/0" ]
  }

  ingress {
    description = "Inbound Jenkins connections"
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = [ "::/0" ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    key = "CI"
  }
}

resource "aws_security_group" "deployment_sg" {
  name = "deployment_sg"
  description = "security group for the deployment server"
  vpc_id = aws_vpc.project_vpc.id

  ingress {
    description = "Inbound HTTP connections"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = [ "::/0" ]
  }

  ingress {
    description = "Inbound SQL connections"
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = [ "::/0" ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    key = "Deployment"
  }
}

resource "aws_security_group" "rds_sg" {
  name = "rds_sg"
  description = "security group for RDS"
  vpc_id = aws_vpc.project_vpc.id

  ingress {
    description = "Inbound SQL connections"
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = [ "::/0" ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    key = "Database"
  }
}

resource "aws_route_table" "project_rt" {
  vpc_id = aws_vpc.lab4_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.project_gw.id
  }

  tags = {
    name = "project_rt"
  }
}

resource "aws_route_table_association" "association1" {
  subnet_id = aws_subnet.project_subnet_1.id
  route_table_id = aws_route_table.project_rt.id
}

resource "aws_route_table_association" "association2" {
  subnet_id = aws_subnet.project_subnet_2.id
  route_table_id = aws_route_table.project_rt.id
}

resource "aws_route_table_association" "association3" {
  subnet_id = aws_subnet.project_subnet_3.id
  route_table_id = aws_route_table.project_rt.id
}

resource "aws_internet_gateway" "project_gw" {
  vpc_id = aws_vpc.project_vpc.id
  tags = {
    name = "project_gw"
  }
}

resource "aws_instance" "ci_instance" {
  ami = "ami-09744628bed84e434"
  instance_type = "t2.micro"
  key_name = may23
  subnet_id = aws_subnet.project_subnet_1.id
  associate_public_ip_address = true
  security_groups = [ aws_security_group.ci_sg.id ]
  tags = {
    name = "ci_server"
    }
}

resource "aws_instance" "deployment_instance" {
  ami = "ami-09744628bed84e434"
  instance_type = "t2.micro"
  key_name = may23
  subnet_id = aws_subnet.project_subnet_2.id
  associate_public_ip_address = true
  security_groups = [ aws_security_group.deployment_sg.id ]
  tags = {
    name = "deploment_server"
    }
}

resource "aws_db_subnet_group" "project_group" {
  name       = "project-db-subnet-group"
  subnet_ids = [aws_subnet.project_subnet_1.id, aws_subnet.project_subnet_2.id, aws_subnet.project_subnet_3.id]  
}


resource "aws_db_instance" "project_rds" {
  allocated_storage    = 10
  db_name              = "project_rds"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = "my-secret-pw"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  vpc_security_group_ids = [ aws_security_group.rds_sg ]
  subnet_group_name = aws_db_subnet_group.project_group.name
}
