provider "aws" {
  region = "us-east-1"
}

# Create a vpc in aws

resource "aws_vpc" "project-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "project-vpc"
  }
}

# Create subnets

resource "aws_subnet" "public_subnet" {
    vpc_id = aws_vpc.project-vpc.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true
    availability_zone = "us-east-1a"
    tags = {
      Name = "public-subnet"
    }
}

resource "aws_subnet" "private_subnet" {
    vpc_id = aws_vpc.project-vpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "us-east-1b"
    tags = {
      Name = "private-subnet"
    }
}

# Create a internet gateway which will enable the vpc to be accessible from internet

resource "aws_internet_gateway" "ig-gw" {
    vpc_id = aws_vpc.project-vpc.id
    tags = {
      Name = "ig-gw"
    }
}

# Create a route table for vpc which has a route from internet any ip to the gateway

resource "aws_route_table" "route_table" {

    vpc_id = aws_vpc.project-vpc.id

    route = [ {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.ig-gw.vpc_id
    } ]
}


# Associating the route table to the subnet

resource "aws_route_table_association" "association" {
    subnet_id = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.route_table.id
}


# Creating an ec2 with existing sg and the key 

resource "aws_instance" "ec2-instance" {
    ami = "ami-example"
    instance_type = "t2.micro"
    key_name = "my-existing-key"
    subnet_id = aws_subnet.private_subnet.id
    vpc_security_group_ids = ["sg-existing"]
    tags = {
      Name = "EC2-Instance"
    }
}


# Creating the app load balancer 

resource "aws_alb" "app-load-balancer" {
    name = "project-alb"
    subnets = [ aws_subnet.public_subnet.id ]
    internal = false
    load_balancer_type = "application"
}

# Create a target group to send request from load balancer to the ec2

resource "aws_lb_target_group" "target_group" {

    name_prefix = "tg"
    port = 443
    protocol = "HTTPS"
    vpc_id = aws_vpc.project-vpc.id
    
}

# Attach the target group with the instance

resource "aws_lb_target_group_attachment" "tg-attachment" {

    target_group_arn = aws_lb_target_group.target_group.arn
    target_id = aws_instance.ec2-instance.id
  
}

# Creating the listener by which the ALB listens to the traffic and forward the request


resource "aws_lb_listener" "als-listener" {

    load_balancer_arn = aws_alb.app-load-balancer.arn
    port = 443
    protocol = "HTTPS"

    default_action {
      type = "forward"
      target_group_arn = aws_lb_target_group.target_group.arn
    }
}

# Enalbing the vpc flow logs assuming we have an existing IAM role with necessary permission to ingest logs to a cloudwatch or direct s3

resource "aws_flow_log" "vpc-flow-logs" {
   iam_role_arn = "existing-iam-role.arn" 
   log_destination = "existing-cloudwatch-log-group.arn"
   traffic_type = "ALL"
   vpc_id = aws_vpc.project-vpc.id
}