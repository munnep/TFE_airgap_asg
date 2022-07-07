


resource "aws_launch_configuration" "as_conf" {
  name_prefix          = "${var.tag_prefix}-lc"
  image_id             = var.ami
  instance_type        = "t3.xlarge"
  security_groups      = [aws_security_group.tfe_server_sg.id]
  iam_instance_profile = aws_iam_instance_profile.profile.name
  key_name      = "${var.tag_prefix}-key"

  root_block_device {
    volume_size = 50

  }

  user_data = templatefile("${path.module}/scripts/user-data.sh", {
    tag_prefix         = var.tag_prefix
    filename_airgap    = var.filename_airgap
    filename_license   = var.filename_license
    filename_bootstrap = var.filename_bootstrap
    dns_hostname       = var.dns_hostname
    tfe_password       = var.tfe_password
    dns_zonename       = var.dns_zonename
    pg_dbname          = aws_db_instance.default.name
    pg_address         = aws_db_instance.default.address
    rds_password       = var.rds_password
    tfe_bucket         = "${var.tag_prefix}-bucket"
    region             = var.region
  })


  lifecycle {
    create_before_destroy = true
  }
}


# # Automatic Scaling group
resource "aws_autoscaling_group" "as_group" {
  name                      = "${var.tag_prefix}-asg"
  max_size                  = var.asg_max_size
  min_size                  = var.asg_min_size
  health_check_grace_period = 3600
  health_check_type         = "ELB"
  desired_capacity          = var.asg_desired_capacity
  force_delete              = true
  launch_configuration      = aws_launch_configuration.as_conf.name
  vpc_zone_identifier       = [aws_subnet.private1.id]
  target_group_arns         = [aws_lb_target_group.lb_target_group1.id, aws_lb_target_group.lb_target_group2.id]


  tag {
    key                 = "Name"
    value               = "${var.tag_prefix}-tfe-asg"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }

  depends_on = [
    aws_nat_gateway.NAT, aws_security_group.tfe_server_sg, aws_internet_gateway.gw, aws_db_instance.default
  ]

}