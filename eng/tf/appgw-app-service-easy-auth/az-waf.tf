resource "azurerm_web_application_firewall_policy" "waf" {
  name                = "waf-policy"
  resource_group_name = var.rg_name
  location            = var.location

  policy_settings {
    enabled = true
    mode    = "Prevention"
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = 3.1

      rule_group_override {
        rule_group_name = "REQUEST-942-APPLICATION-ATTACK-SQLI"

        disabled_rules = ["942200", "942260", "942310", "942340", "942370"]
      }
    }
  }

  custom_rules {
    name      = "AllowEasyAuthCallback"
    priority  = 1
    rule_type = "MatchRule"

    match_conditions {
      match_variables {
        variable_name = "RequestUri"
      }
      operator           = "EndsWith"
      negation_condition = false
      match_values       = ["/.auth/login/aad/callback"]
      transforms         = ["Lowercase"]
    }
    action = "Allow"
  }

  custom_rules {
    name      = "BlockSpecificRoutes"
    priority  = 5
    rule_type = "MatchRule"

    match_conditions {
      match_variables {
        variable_name = "RequestUri"
      }
      operator           = "Contains"
      negation_condition = false
      match_values       = ["/privacy", "/admin"]
      transforms         = ["Lowercase"]
    }
    action = "Block"
  }
}
