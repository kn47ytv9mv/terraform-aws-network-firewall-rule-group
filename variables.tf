variable "name" {
  default     = null
  description = "Name of the rule group. If null, a unique name is generated."
}

variable "description" {
  default     = null
  description = "A description of the rule group."
}

variable "type" {
  default     = null
  description = "'STATEFUL' (Suricata-compatible, connection-aware rules — set rules_string) or 'STATELESS' (single-packet 5-tuple rules, evaluated first, no connection state — set stateless_rules)."

  validation {
    condition     = var.type == null || contains(["STATEFUL", "STATELESS"], var.type)
    error_message = "type must be 'STATEFUL' or 'STATELESS'."
  }

  validation {
    condition     = var.type != "STATELESS" || var.rules_string == null
    error_message = "rules_string is Suricata format, which only applies to a STATEFUL rule group — use stateless_rules for STATELESS instead."
  }

  validation {
    condition     = var.type != "STATEFUL" || length(var.stateless_rules) == 0
    error_message = "stateless_rules only applies to a STATELESS rule group — use rules_string for STATEFUL instead."
  }
}

variable "capacity" {
  default     = null
  description = "The rule group's capacity, in AWS's own capacity units — an upper bound on the rules it can hold, set at creation and immutable afterward. AWS computes and reports the actual amount consumed on the capacity output; set this to at least that, with headroom for rules added later."
}

variable "rules_string" {
  default     = null
  description = "Stateful rules in Suricata format, as a single string — the common way to author a STATEFUL rule group's rules. Only used when type is 'STATEFUL'."
}

variable "stateless_rules" {
  default     = []
  description = "Stateless rules, only used when type is 'STATELESS'. Each needs a priority (evaluation order, lower first), one or more actions (e.g. 'aws:pass', 'aws:drop', 'aws:forward_to_sfe'), and match criteria — an empty list for a field matches everything."
  type = list(object({
    priority = number
    actions  = list(string)
    match_attributes = object({
      protocols         = optional(list(number), [])
      source_cidrs      = optional(list(string), [])
      destination_cidrs = optional(list(string), [])
      source_ports = optional(list(object({
        from_port = number
        to_port   = optional(number)
      })), [])
      destination_ports = optional(list(object({
        from_port = number
        to_port   = optional(number)
      })), [])
      tcp_flags = optional(list(object({
        flags = list(string)
        masks = optional(list(string), [])
      })), [])
    })
  }))
}

variable "ip_sets" {
  default     = {}
  description = "Named CIDR groups, keyed by the name rules_string references (e.g. 'HOME_NET'). Each entry is a list of CIDR blocks."
  type        = map(list(string))
}

variable "port_sets" {
  default     = {}
  description = "Named port groups, keyed by the name rules_string references (e.g. 'HTTP_PORTS'). Each entry is a list of ports or port ranges as strings (e.g. '443', '8000:8999')."
  type        = map(list(string))
}

variable "tags" {
  default     = null
  description = "A map of tags to assign to the rule group."
}
