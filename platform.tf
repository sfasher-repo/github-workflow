resource "aws_s3_bucket" "prod_s3_bucket" {
  bucket = "stf-tf-backend-${var.env}"
}

resource "aws_default_vpc" "default" {
}

resource "aws_default_subnet" "default_az1" {
  availability_zone = "eu-west-2a"

  tags = {
    "Terraform" : "true"
  }
}

resource "aws_default_subnet" "default_az2" {
  availability_zone = "eu-west-2b"

  tags = {
    "Terraform" : "true"
  }
}

resource "aws_security_group" "prod_web" {
  name        = "${var.env}-web"
  description = "Allow Standard HTTP/S ports inbound and all outbound"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.whitelist
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.whitelist
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.whitelist
  }

  tags = {
    "Terraform" : "true"
  }
}
# resource "aws_instance" "prod_web" {
#     count                   = 2

#     ami                     = "ami-01ae4488af6c6f65b"
#     instance_type           = "t2.nano"

#     vpc_security_group_ids = [
#         aws_security_group.prod_web.id
#     ]

#     tags = {
#         "Terraform" : "true"
#         }   
# }


# resource "aws_eip_association" "prod_web" {
#     instance_id     = aws_instance.prod_web.0.id
#     allocation_id   = aws_eip.prod_web_ip.id
# }

# resource "aws_eip" "prod_web_ip" {
#     tags = {
#         "Terraform" : "true"
#         }  
# }

resource "aws_elb" "prod_web_elb" {
  name = "${var.env}-web"
  # instances       = aws_instance.prod_web.*.id 
  subnets         = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
  security_groups = [aws_security_group.prod_web.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  tags = {
    "Terraform" : "true"
  }

}

resource "aws_launch_template" "prod_web" {
  name_prefix   = "${var.env}-web"
  image_id      = var.web_image_id
  instance_type = var.web_instance_type

  tags = {
    "Terraform" : "true"
  }
}

resource "aws_autoscaling_group" "prod_web" {
  availability_zones = ["eu-west-2a", "eu-west-2b"]
  #   vpc_zone_identifier = [aws_default_subnet.default_az1.id,aws_default_subnet.default_az2.id]
  desired_capacity = var.web_desired_capacity
  max_size         = var.web_max_size
  min_size         = var.web_min_size

  launch_template {
    id      = aws_launch_template.prod_web.id
    version = "$Latest"
  }

  tag {
    key                 = "Terraform"
    value               = "true"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_attachment" "prod_web" {
  autoscaling_group_name = aws_autoscaling_group.prod_web.id
  elb                    = aws_elb.prod_web_elb.id
}

resource "aws_internet_gateway" "prod_igw" {
  vpc_id = aws_default_vpc.default.id

}