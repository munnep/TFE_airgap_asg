
resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.base_domain.zone_id
  name    = var.dns_hostname
  type    = "CNAME"
  ttl     = "300"
  records = [aws_lb.lb_application.dns_name]
}
