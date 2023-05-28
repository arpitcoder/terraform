provider "aws" {
   region     = "ap-south-1"
   access_key = "AKIAZ3KAAWE7527DIQUB"
   secret_key = "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"
   
}

resource "aws_instance" "k8s-master" {

    ami = "ami-0022f774911c1d690"  
    instance_type = "t2.xlarge" 
    key_name= "aws_key"
    vpc_security_group_ids = [aws_security_group.main.id]

}
resource "aws_instance" "k8s-worker" {

    ami = "ami-0022f774911c1d690"  
    instance_type = "t2.xlarge" 
    key_name= "aws_key"
    vpc_security_group_ids = [aws_security_group.main.id]

}

resource "aws_security_group" "main" {
  egress = [
    {
      cidr_blocks      = [ "0.0.0.0/0", ]
      description      = ""
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups  = []
      self             = false
      to_port          = 0
    }
  ]
 ingress                = [
   {
     cidr_blocks      = [ "0.0.0.0/0", ]
     description      = ""
     from_port        = 22
     ipv6_cidr_blocks = []
     prefix_list_ids  = []
     protocol         = "tcp"
     security_groups  = []
     self             = false
     to_port          = 22
  }
  ]
}

