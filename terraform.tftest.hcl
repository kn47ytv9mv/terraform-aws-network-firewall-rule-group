mock_provider "aws" {
}

run "type_invalid_rejected" {
  command = plan

  variables {
    type     = "SIDEWAYS"
    capacity = 100
  }

  expect_failures = [var.type]
}

run "rejects_rules_string_on_stateless_type" {
  command = plan

  variables {
    type         = "STATELESS"
    capacity     = 100
    rules_string = "alert tcp any any -> any any (msg:\"test\"; sid:1;)"
  }

  expect_failures = [var.type]
}

run "rejects_stateless_rules_on_stateful_type" {
  command = plan

  variables {
    type     = "STATEFUL"
    capacity = 100
    stateless_rules = [{
      priority = 1
      actions  = ["aws:pass"]
      match_attributes = {
        source_cidrs = ["10.0.0.0/16"]
      }
    }]
  }

  expect_failures = [var.type]
}

run "stateful_rules_string_passes_through" {
  command = plan

  variables {
    type         = "STATEFUL"
    capacity     = 100
    rules_string = "alert tcp any any -> any any (msg:\"test\"; sid:1;)"
  }

  assert {
    condition     = aws_networkfirewall_rule_group.resource.rule_group[0].rules_source[0].rules_string == "alert tcp any any -> any any (msg:\"test\"; sid:1;)"
    error_message = "rules_string should pass through unchanged."
  }
}

run "stateless_rules_render" {
  command = plan

  variables {
    type     = "STATELESS"
    capacity = 100
    stateless_rules = [
      {
        priority = 1
        actions  = ["aws:pass"]
        match_attributes = {
          protocols         = [6]
          source_cidrs      = ["10.0.0.0/16"]
          destination_cidrs = ["0.0.0.0/0"]
          destination_ports = [{ from_port = 443 }]
        }
      }
    ]
  }

  assert {
    condition     = length(aws_networkfirewall_rule_group.resource.rule_group[0].rules_source[0].stateless_rules_and_custom_actions[0].stateless_rule) == 1
    error_message = "One stateless_rules entry should render exactly one stateless_rule block."
  }
}

run "ip_sets_and_port_sets_render" {
  command = plan

  variables {
    type         = "STATEFUL"
    capacity     = 100
    rules_string = "alert tcp $HOME_NET any -> any $HTTP_PORTS (msg:\"test\"; sid:1;)"
    ip_sets = {
      HOME_NET = ["10.0.0.0/16"]
    }
    port_sets = {
      HTTP_PORTS = ["80", "443"]
    }
  }

  assert {
    condition     = length(aws_networkfirewall_rule_group.resource.rule_group[0].rule_variables) == 1
    error_message = "Non-empty ip_sets/port_sets should render exactly one rule_variables block."
  }
}

run "no_ip_sets_or_port_sets_omits_rule_variables" {
  command = plan

  variables {
    type         = "STATEFUL"
    capacity     = 100
    rules_string = "alert tcp any any -> any any (msg:\"test\"; sid:1;)"
  }

  assert {
    condition     = length(aws_networkfirewall_rule_group.resource.rule_group[0].rule_variables) == 0
    error_message = "Empty ip_sets and port_sets should omit the rule_variables block entirely."
  }
}

run "tags_pass_through" {
  command = plan

  variables {
    type         = "STATEFUL"
    capacity     = 100
    rules_string = "alert tcp any any -> any any (msg:\"test\"; sid:1;)"
    tags = {
      Name = "example-rule-group"
    }
  }

  assert {
    condition     = aws_networkfirewall_rule_group.resource.tags.Name == "example-rule-group"
    error_message = "tags should pass through unchanged."
  }
}

run "readme_stateful_example" {
  command = plan

  variables {
    type         = "STATEFUL"
    capacity     = 100
    rules_string = "alert tcp $HOME_NET any -> any $HTTP_PORTS (msg:\"test\"; sid:1;)"
    ip_sets = {
      HOME_NET = ["10.0.0.0/16"]
    }
    port_sets = {
      HTTP_PORTS = ["80", "443"]
    }
  }
}

run "readme_stateless_example" {
  command = plan

  variables {
    type     = "STATELESS"
    capacity = 100
    stateless_rules = [
      {
        priority = 1
        actions  = ["aws:drop"]
        match_attributes = {
          source_cidrs = ["198.51.100.0/24"]
        }
      }
    ]
  }
}
