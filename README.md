# terraform-aws-network-firewall-rule-group

Terraform module for an AWS Network Firewall rule group — a reusable
set of stateful or stateless traffic-inspection rules, attached to a
[`terraform-aws-network-firewall-policy`](https://github.com/kn47ytv9mv/terraform-aws-network-firewall-policy)
by ARN.

## Cost

A rule group has no charge of its own — Network Firewall bills the
firewall endpoint itself (per-hour, per-AZ) and per-GB of traffic it
processes. See AWS's
[Network Firewall pricing](https://aws.amazon.com/network-firewall/pricing/)
page for current rates.

## Design

`type` picks one of two genuinely different rule shapes:

- **`'STATEFUL'`**: connection-aware rules, authored in `rules_string`
  as a single Suricata-format string — the standard way most
  real-world Network Firewall stateful rule groups are written, and
  what this module models directly rather than AWS's alternative
  structured 5-tuple format. `ip_sets`/`port_sets` define named
  groups (`$HOME_NET`, `$HTTP_PORTS`) that string can reference.
- **`'STATELESS'`**: single-packet rules with no connection state,
  evaluated before any stateful rule — `stateless_rules` models these
  structurally, since (unlike a stateful rule's arbitrary Suricata
  syntax) a stateless rule's match criteria are a bounded, flat set of
  fields (protocol, source/destination CIDR, source/destination port,
  TCP flags).

`rules_string` and `stateless_rules` are mutually exclusive by
`type` — a `validation` block rejects setting the one that does not
match.

## Usage

A stateful rule group in Suricata format:

```hcl
module "rule_group" {
  source = "kn47ytv9mv/network-firewall-rule-group/aws"

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
```

Or directly from this repository, a stateless rule dropping traffic
from a known-bad CIDR:

```hcl
module "rule_group" {
  source = "github.com/kn47ytv9mv/terraform-aws-network-firewall-rule-group"

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
```

## Requirements

| Name | Version |
|---|---|
| terraform | >= 1.9 |
| aws | ~> 6.61 |
| random | ~> 3.9 |

## Providers

| Name | Version |
|---|---|
| aws | ~> 6.61 |
| random | ~> 3.9 |

## Inputs

| Name | Description | Default | Required |
|---|---|---|---|
| name | Name of the rule group. If null, a unique name is generated. | `null` | no |
| description | A description of the rule group. | `null` | no |
| type | 'STATEFUL' (Suricata-compatible, connection-aware rules — set rules_string) or 'STATELESS' (single-packet 5-tuple rules, evaluated first, no connection state — set stateless_rules). | `null` | no |
| capacity | The rule group's capacity, in AWS's own capacity units — an upper bound on the rules it can hold, set at creation and immutable afterward. AWS computes and reports the actual amount consumed on the capacity output; set this to at least that, with headroom for rules added later. | `null` | no |
| rules_string | Stateful rules in Suricata format, as a single string — the common way to author a STATEFUL rule group's rules. Only used when type is 'STATEFUL'. | `null` | no |
| stateless_rules | Stateless rules, only used when type is 'STATELESS'. Each needs a priority (evaluation order, lower first), one or more actions (e.g. 'aws:pass', 'aws:drop', 'aws:forward_to_sfe'), and match criteria — an empty list for a field matches everything. | `[]` | no |
| ip_sets | Named CIDR groups, keyed by the name rules_string references (e.g. 'HOME_NET'). Each entry is a list of CIDR blocks. | `{}` | no |
| port_sets | Named port groups, keyed by the name rules_string references (e.g. 'HTTP_PORTS'). Each entry is a list of ports or port ranges as strings (e.g. '443', '8000:8999'). | `{}` | no |
| tags | A map of tags to assign to the rule group. | `null` | no |

## Outputs

| Name | Description |
|---|---|
| id | The ID of the rule group. |
| arn | The ARN of the rule group — pass to terraform-aws-network-firewall-policy's stateful_rule_group_arns or stateless_rule_group_arns. |
| name | The name of the rule group. |

## License

MIT — see [LICENSE.md](LICENSE.md).
