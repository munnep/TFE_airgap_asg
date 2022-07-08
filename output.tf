output "ssh_tf_client" {
  value = "ssh ubuntu@${var.dns_hostname}-client.${var.dns_zonename}"
}

output "tfe_dashboard" {
  value = "https://${var.dns_hostname}.${var.dns_zonename}:8800"
}

output "tfe_appplication" {
  value = "https://${var.dns_hostname}.${var.dns_zonename}"
}

data "aws_instance" "tfe" {

  filter {
    name   = "instance-state-name"
    values = ["pending", "running"]
  }

  filter {
    name   = "tag:Name"
    values = ["tfe-airgap-asg-tfe-asg"]
  }
}

output "ssh_tfe_server" {
  value = "ssh -J ubuntu@${var.dns_hostname}-client.${var.dns_zonename} ubuntu@${data.aws_instance.tfe.private_ip}"
}

