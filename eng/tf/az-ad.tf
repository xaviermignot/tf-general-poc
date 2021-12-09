resource "azuread_application" "easy_auth" {
  display_name = "app-${var.project}"

  api {
    requested_access_token_version = 2
  }

  web {
    redirect_uris = ["https://web-${var.project}-auth.azurewebsites.net/.auth/login/aad/callback"]

    implicit_grant {
      access_token_issuance_enabled = true
      id_token_issuance_enabled     = true
    }
  }

  group_membership_claims = ["ApplicationGroup", "SecurityGroup"]

  optional_claims {
    access_token {
      name = "groups"
    }

    id_token {
      name = "groups"
    }

    saml2_token {
      name = "groups"
    }
  }

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    resource_access {
      id   = "37f7f235-527c-4136-accd-4a02d197296e" # User sign-in
      type = "Scope"
    }
  }
}

resource "azuread_application_password" "easy_auth" {
  application_object_id = azuread_application.easy_auth.object_id
}

resource "azuread_service_principal" "easy_auth" {
  application_id               = azuread_application.easy_auth.application_id
  app_role_assignment_required = true
}

resource "azuread_group" "easy_auth" {
  display_name     = "Group for easy auth in Web App web-${var.project}"
  security_enabled = true
}

resource "azuread_app_role_assignment" "easy_auth" {
  for_each = {
    "group" = azuread_group.easy_auth.object_id
  }

  app_role_id         = "00000000-0000-0000-0000-000000000000"
  principal_object_id = each.value
  resource_object_id  = azuread_service_principal.easy_auth.object_id
}

data "azuread_client_config" "current" {}
