#####################################################################
provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region = "us-east-1"
}
#########################VPC#########################################
resource "aws_vpc" "Bank_Host_vpc" {
  cidr_block       = "10.0.0.0/16"
  tags = {
    Name = "Bank_Host_vpc"
  }
}
#######################SUBNET##########################################
resource "aws_subnet" "Public_1" {
    cidr_block = "10.0.1.0/24"
    vpc_id = aws_vpc.Bank_Host_vpc.id
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = true  
}

resource "aws_subnet" "Public_2" {
    cidr_block = "10.0.2.0/24"
    vpc_id = aws_vpc.Bank_Host_vpc.id
    availability_zone = "us-east-1b"
    map_public_ip_on_launch = true  
}

####################SECURITY_GROUP#######################################
resource "aws_security_group" "pub1_sercurity" {
  name ="pub1_sercurity"
  description = "pub1_sercurity"
  vpc_id = aws_vpc.Bank_Host_vpc.id


  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 8000
    to_port = 8000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

#####################################EC2#################################################
resource "aws_instance" "app_server" {
  ami           = "ami-053b0d53c279acc90"
  instance_type = "t2.medium"
  availability_zone = "us-east-1a" # Specify the desired availability zone
  subnet_id = aws_subnet.Public_1.id
  vpc_security_group_ids = [aws_security_group.pub1_sercurity.id]
  key_name = "KevinGonzalez623key"
  user_data = "${file("jenkins_install.sh")}"
  tags = {
    Name = "Jenkins"
  }

}

resource "aws_instance" "app_server_2" {
  ami           = "ami-053b0d53c279acc90"
  instance_type = "t2.medium"
  availability_zone = "us-east-1b" # Specify the desired availability zone
  subnet_id = aws_subnet.Public_2.id
  vpc_security_group_ids = [aws_security_group.pub1_sercurity.id]
  key_name = "KevinGonzalez623key"
  tags = {
    Name = "App_py"
  }
}

#######################IGW##################################################################
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.Bank_Host_vpc.id

  tags = {
    Name = "gw_d5"
  }
}

###################ROUTE_TABLE#######################################################################
resource "aws_route_table" "route_d5" {
  vpc_id = aws_vpc.Bank_Host_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

########################LINKRT#################################################
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.Public_1.id
  route_table_id = aws_route_table.route_d5.id
}


resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.Public_2.id
  route_table_id = aws_route_table.route_d5.id
}
