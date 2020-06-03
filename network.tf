#-----------------create VPC 1 step---------------------------------------------
resource "aws_vpc" "dimalan" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  #main_route_table_id = "aws_route_table.r.id"

  tags = {
    Name = "Newlan"
  }
}
/*
resource "aws_vpc" "access2" {
  cidr_block       = "192.168.1.0/24"
  instance_tenancy = "dedicated"

  tags = {
    Name = "acsess"
  }
}
*/
resource "aws_eip" "nat" {
  vpc = true

}

resource "aws_nat_gateway" "gw" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.private_subnet_A.id}"
}


resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.access_subnet_A.id
  route_table_id = aws_route_table.r.id
}
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.private_subnet_A.id
  route_table_id = aws_route_table.private_route.id
}

#-------------------create gateway----------------------------------------
resource "aws_internet_gateway" "access_gateway" {
  vpc_id = "${aws_vpc.dimalan.id}"
}
#---------------------create subnet----------------------------------------
resource "aws_subnet" "access_subnet_A" {
  vpc_id                  = "${aws_vpc.dimalan.id}"
  cidr_block              = "192.168.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "acsess-subnet"
  }
}
resource "aws_subnet" "private_subnet_A" {
  vpc_id            = "${aws_vpc.dimalan.id}"
  cidr_block        = "192.168.2.0/24"
  availability_zone = "us-east-1a"
  #map_public_ip_on_launch = "true"

  tags = {
    Name = "private-subnet"
  }
}

#----------------Create route tables-----------------------------------------
resource "aws_route_table" "private_route" {
  vpc_id = "${aws_vpc.dimalan.id}"

  route {
    cidr_block = "0.0.0.0/0"

    gateway_id = "${aws_nat_gateway.gw.id}"
  }


  tags = {
    Name = "private_route_table"
  }
}
#----------------Create route tables private-----------------------------------------

resource "aws_route_table" "r" {
  vpc_id = "${aws_vpc.dimalan.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.access_gateway.id}"

  }


  tags = {
    Name = "access_route_table"
  }
}

#-----------------------------------------------------------------------------
provider "aws" {
  region = "us-east-1"
}
resource "aws_instance" "network-test" {
  ami           = "${var.ami}"
  instance_type = "${var.instance_type}"
  subnet_id     = "${aws_subnet.access_subnet_A.id}"
  key_name      = "dima2"
  #depends_on    = ["aws_internet_gateway.access_gateway"]
  /*user_data     = "${data.template_file.script.rendered}"*/
  tags = {
    Name      = "network_test"
    Terraform = "true"
  }
  vpc_security_group_ids = [aws_security_group.allow_http_EFS_SSH.id]


  connection {
    type = "ssh"
    user = "ec2-user"
    host = self.public_ip
  }
}


/*resource "aws_key_pair" "dima2" {
  key_name   = "dima2"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC1KJNpi6mKA8wOTRxIroSZytjxI2i7VCJ9AS0vP7lSC7WlEELkrFIJPxaTARBd8Q2bUZs53q6OyoU704nK0eBxVBRJKtgy+3ngyZ+dKLEMeq0MzokbRyGoHZT3M/vmdVEhbP7+AHCFpYDs49f559f8pv8pxru3Z1Bv7ytXSqRefqhBG6V6QEc+ZKa7FoF5Je+QM5TwE4LXXREsDvDDIuv30WMou9dH+5wptMj++5DufnL5ssnzH5xjsn6QBObpciqVn9OVyFLWL7SWkFS3yFR1i9dN+JKUZ5DW/s0v+PagEsNxIkaQ3eW08KYcAcKKWpWxnVnkvX5yl7C9ImwL6Mvv dima2"
}*/

resource "aws_security_group" "allow_http_EFS_SSH" {
  name        = "allow_http_EFS_SSH_new"
  description = "Allow http inbound traffic"
  vpc_id      = "${aws_vpc.dimalan.id}"

  dynamic "ingress" {
    for_each = ["80", "22", "2049"]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

variable "ami" {
  default = "ami-01d025118d8e760db"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "AWS_REGION" {
  default = "us-west-1"
}
/*variable "subnet" {
    default = "subnet-b9191487"
  }/*

  /*variable "root_password" {}*/

variable "host" {
  type    = string
  default = "test-network"
}
