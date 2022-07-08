# loadbalancer Target Group
resource "aws_lb_target_group" "lb_target_group1" {
  name     = "${var.tag_prefix}-target-group1"
  port     = 8800
  protocol = "HTTPS"
  vpc_id   = aws_vpc.main.id
}

# loadbalancer Target Group
resource "aws_lb_target_group" "lb_target_group2" {
  name     = "${var.tag_prefix}-target-group2"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = aws_vpc.main.id
}

# loadbalancer Target Group
resource "aws_lb_target_group" "lb_target_group3" {
  name     = "${var.tag_prefix}-target-group3"
  port     = 19999
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}


# application load balancer
resource "aws_lb" "lb_application" {
  name               = "${var.tag_prefix}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.tfe_server_sg.id]
  subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]

  tags = {
    Environment = "${var.tag_prefix}-lb"
  }
}

resource "aws_lb_listener" "front_end1" {
  load_balancer_arn = aws_lb.lb_application.arn
  port              = "8800"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.cert.arn


  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group1.arn
  }
}

resource "aws_lb_listener" "front_end2" {
  load_balancer_arn = aws_lb.lb_application.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.cert.arn


  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group2.arn
  }
}

resource "aws_lb_listener" "front_end3" {
  load_balancer_arn = aws_lb.lb_application.arn
  port              = "19999"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group3.arn
  }
}