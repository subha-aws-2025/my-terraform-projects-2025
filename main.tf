resource "aws_vpc" "myvpc" { #This is to create the VPC
  cidr_block = var.cidr
}

resource "aws_subnet" "public_subnet_1" { #This is Public Subnet 1 with Public IP enabled
  cidr_block              = "10.0.0.0/24"
  vpc_id                  = aws_vpc.myvpc.id
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_subnet_2" { #This is Public Subnet 2 with Public IP enabled
  cidr_block              = "10.0.2.0/24"
  vpc_id                  = aws_vpc.myvpc.id
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "myigw" { #This is IGW attached to the VPC 
  vpc_id = aws_vpc.myvpc.id
}

resource "aws_route_table" "myroutetable1" { # VPC route table with routes to the igw
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myigw.id

  }

  tags ={
    name = "my-project"
  }
}

resource "aws_route_table_association" "RT1" { #Associate the route table to the subnet 1
  route_table_id = aws_route_table.myroutetable1.id
  subnet_id      = aws_subnet.public_subnet_1.id
}

resource "aws_route_table_association" "RT2" { #Associate the route table to the subnet 2
  route_table_id = aws_route_table.myroutetable1.id
  subnet_id      = aws_subnet.public_subnet_2.id
}

resource "aws_security_group" "Project_AC" { #Security Group Creation and adding inbound rules
  name   = "Project_AC"
  vpc_id = aws_vpc.myvpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_security_group_ingress_rule" "Allow_SSH" {
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.Project_AC.id
  from_port         = 22
  to_port           = 22
}


resource "aws_vpc_security_group_ingress_rule" "Allow_HTTP" {
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.Project_AC.id
  from_port         = 80
  to_port           = 80
}

resource "aws_s3_bucket" "mybucket" {  #To create S3 bucket
    bucket = "my-subha-role-example-bucket" 
}

resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket.mybucket.bucket
  key    = "subhashini/role-example/test1.txt"
  source = "/workspaces/terraform-zero-to-hero/Day-2/subha/role-example/test1.txt"
}

resource "aws_iam_role" "test_role" {
  name = "test_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "terraform-role-example"
  }
}
resource "aws_iam_role_policy" "test_policy" {
  name = "test_policy"
  role = aws_iam_role.test_role.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_instance_profile" "my-ec2-profile" {
  name = "my-ec2-profile"
  role = aws_iam_role.test_role.id
}
resource "aws_instance" "my-example-1" {
    ami = var.myami
    instance_type = var.myinstancetype
    subnet_id = aws_subnet.public_subnet_1.id
    vpc_security_group_ids = [aws_security_group.Project_AC.id]
    user_data = base64encode(file("userdata.sh"))
    iam_instance_profile = aws_iam_instance_profile.my-ec2-profile.id
    
}
resource "aws_instance" "my-example-2" {
    ami = var.myami
    instance_type = var.myinstancetype
    subnet_id = aws_subnet.public_subnet_1.id
    vpc_security_group_ids = [aws_security_group.Project_AC.id]
    user_data = base64encode(file("userdata.sh"))
    iam_instance_profile = aws_iam_instance_profile.my-ec2-profile.id
    
}
#create application load balancer
resource "aws_lb" "test" {
  name               = "my-loadbalancer-test"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.Project_AC.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}

resource "aws_lb_target_group" "test-alb" {
  name     = "example-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.myvpc.id

}

resource "aws_lb_listener" "test_alb_listener" {
  load_balancer_arn = aws_lb.test.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test-alb.arn
  }
}

resource "aws_lb_target_group_attachment" "mytg-attachement" {
  target_group_arn = aws_lb_target_group.test-alb.arn
  target_id        = aws_instance.my-example-1.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "mytg-attachement2" {
  target_group_arn = aws_lb_target_group.test-alb.arn
  target_id        = aws_instance.my-example-2.id
  port             = 80
}

output "loadbalancerdns" {
  value = aws_lb.test.dns_name
}
