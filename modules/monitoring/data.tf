data "aws_instances" "asg_members" {
  filter {
    name   = "tag:aws:autoscaling:groupName"
    values = [var.resource_name_prefix]
  }
}

data "aws_instance" "by_id" {
  for_each    = toset(data.aws_instances.asg_members.ids)
  instance_id = each.value
}

locals {
  id_to_name = {
    for id, inst in data.aws_instance.by_id :
    id => coalesce(try(inst.tags["Name"], null), id)
  }
}
