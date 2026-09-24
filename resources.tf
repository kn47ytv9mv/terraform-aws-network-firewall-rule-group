resource "random_uuid" "resource" {}

resource "aws_networkfirewall_rule_group" "resource" {
  name        = coalesce(var.name, random_uuid.resource.id)
  description = var.description
  type        = var.type
  capacity    = var.capacity

  rule_group {
    dynamic "rule_variables" {
      for_each = length(var.ip_sets) > 0 || length(var.port_sets) > 0 ? [1] : []

      content {
        dynamic "ip_sets" {
          for_each = var.ip_sets

          content {
            key = ip_sets.key
            ip_set {
              definition = ip_sets.value
            }
          }
        }

        dynamic "port_sets" {
          for_each = var.port_sets

          content {
            key = port_sets.key
            port_set {
              definition = port_sets.value
            }
          }
        }
      }
    }

    rules_source {
      rules_string = var.rules_string

      dynamic "stateless_rules_and_custom_actions" {
        for_each = length(var.stateless_rules) > 0 ? [1] : []

        content {
          dynamic "stateless_rule" {
            for_each = var.stateless_rules

            content {
              priority = stateless_rule.value.priority

              rule_definition {
                actions = stateless_rule.value.actions

                match_attributes {
                  protocols = stateless_rule.value.match_attributes.protocols

                  dynamic "source" {
                    for_each = stateless_rule.value.match_attributes.source_cidrs
                    content {
                      address_definition = source.value
                    }
                  }

                  dynamic "destination" {
                    for_each = stateless_rule.value.match_attributes.destination_cidrs
                    content {
                      address_definition = destination.value
                    }
                  }

                  dynamic "source_port" {
                    for_each = stateless_rule.value.match_attributes.source_ports
                    content {
                      from_port = source_port.value.from_port
                      to_port   = coalesce(source_port.value.to_port, source_port.value.from_port)
                    }
                  }

                  dynamic "destination_port" {
                    for_each = stateless_rule.value.match_attributes.destination_ports
                    content {
                      from_port = destination_port.value.from_port
                      to_port   = coalesce(destination_port.value.to_port, destination_port.value.from_port)
                    }
                  }

                  dynamic "tcp_flag" {
                    for_each = stateless_rule.value.match_attributes.tcp_flags
                    content {
                      flags = tcp_flag.value.flags
                      masks = tcp_flag.value.masks
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  tags = var.tags
}

output "id" {
  description = "The ID of the rule group."
  value       = aws_networkfirewall_rule_group.resource.id
}

output "name" {
  description = "The name of the rule group."
  value       = aws_networkfirewall_rule_group.resource.name
}

output "arn" {
  description = "The ARN of the rule group — pass to terraform-aws-network-firewall-policy's stateful_rule_group_arns or stateless_rule_group_arns."
  value       = aws_networkfirewall_rule_group.resource.arn
}
