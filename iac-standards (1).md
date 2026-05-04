# Infrastructure as Code (IaC) Standards

> **Version:** 1.0 | **Status:** ✅ Active | **Last Updated:** April 2026  
> This document defines the **mandatory standards** for implementing Infrastructure as Code (IaC) for any application onboarded to this platform. Every new application, module, or environment addition **must** follow these standards.

---

## Table of Contents

1. [Overview](#1-overview)
2. [Repository & Folder Structure](#2-repository--folder-structure)
3. [Naming Convention Standard](#3-naming-convention-standard)
4. [Module Design Standards](#4-module-design-standards)
5. [Environment Configuration Standards](#5-environment-configuration-standards)
6. [Common & Project Module Responsibilities](#6-common--project-module-responsibilities)
7. [Terraform Cloud Workspace Setup](#7-terraform-cloud-workspace-setup)
8. [CI/CD Pipeline Integration](#8-cicd-pipeline-integration)
9. [Secret & Variable Management](#9-secret--variable-management)
10. [End-to-End: Adding a New Application](#10-end-to-end-adding-a-new-application)
11. [End-to-End: Adding a New Module](#11-end-to-end-adding-a-new-module)
12. [Tagging Standard](#12-tagging-standard)
13. [Do's and Don'ts](#13-dos-and-donts)

---

## 1. Overview

This repository manages Azure infrastructure for one or more applications using [Terraform](https://www.terraform.io/) as the sole IaC tool. Each application is identified by an **`app_code`** (e.g. a short identifier for the application) and a **`business_unit`**.

**Key principles:**

- All Azure infrastructure is defined and managed **only** through Terraform — no manual provisioning.
- Reusable infrastructure logic lives in **modules**; environment-specific values live in **env folders**.
- All Terraform runs are executed through **Terraform Cloud**, triggered via **GitHub Actions**.
- No `terraform.tfvars` files — secrets and variables are supplied exclusively through GitHub Actions secrets/variables and Terraform Cloud workspace variables.

---

## 2. Repository & Folder Structure

```text
infra/
├── modules/                          # Reusable Terraform modules (shared across all apps & envs)
│   ├── common/                       # Dynamic naming, tags, subscriptions, AD groups
│   │   ├── locals.tf                 # Naming logic, resource type codes
│   │   ├── variables.tf              # Input: app_code, environment, location, etc.
│   │   └── outputs.tf                # Resource names, tags, subscriptions
│   │
│   ├── project/                      # App-level configs (SKUs, app setting keys)
│   │   ├── locals.tf                 # Per-project, per-env config (SKU, autoscale, etc.)
│   │   └── outputs.tf                # Expose project configs
│   │
│   ├── app_service_plan/             # Azure App Service Plan
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── app_service/                  # Azure Linux Web App
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── container_registry/           # Azure Container Registry
│   ├── storage_account/              # Azure Storage Account
│   ├── monitoring/                   # Application Insights + Log Analytics
│   ├── alerts/                       # Monitor Metric Alerts
│   ├── action_groups/                # Monitor Action Groups
│   ├── app_service_autoscaler/       # Autoscale Settings
│   ├── availability_tests/           # Availability / Ping Tests
│   ├── custom_hostname_binding/      # Custom Domain Bindings
│   ├── event_grid/                   # EventGrid System Topics
│   ├── sso_app/                      # SSO / AAD App Registration
│   └── {new_module}/                 # Each new Azure resource type = one module
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
└── envs/                             # Environment-specific root configurations
    ├── dev/                          # Development environment
    │   └── {app_code}/               # One folder per application
    │       ├── backend.tf            # Terraform Cloud workspace binding
    │       ├── providers.tf          # Azure provider + version pins
    │       ├── common.tf             # Instantiates common & project modules
    │       ├── locals.tf             # Environment-specific local values
    │       ├── main.tf               # All module instantiations for this env
    │       ├── outputs.tf            # Outputs exposed from this env
    │       └── resource_group.tf     # Data source for existing RG
    │
    ├── qa/                           # QA environment (mirrors dev structure)
    │   └── {app_code}/
    │
    └── prod/                         # Production environment (mirrors dev structure)
        └── {app_code}/
```

### Rules

| Rule | Rationale |
|:---- |:--------- |
| Each **Azure resource type** gets its own module folder under `modules/` | Reusability, testability, single responsibility |
| Each **project × environment** gets its own folder under `envs/` | Full isolation; a broken dev config cannot affect prod |
| Module folders contain **only** `main.tf`, `variables.tf`, `outputs.tf` (+ optional `README.md`) | Predictable structure for all contributors |
| Environment folders contain **only** `backend.tf`, `providers.tf`, `common.tf`, `locals.tf`, `main.tf`, `outputs.tf`, `resource_group.tf` (+ data sources) | Prevents environment folders from becoming monoliths |

---

## 3. Naming Convention Standard

### Formula

```
{SERVICE_TYPE}{ENV_CODE}{CLOUD}{REGION_CODE}{ACCESS}{APP_CODE}{RESOURCE_TYPE_CODE}{ITERATION}
```

| Segment          | Values / Source                              | Example   |
|:---------------- |:-------------------------------------------- |:--------- |
| `SERVICE_TYPE`   | `B` = Services                               | `B`       |
| `ENV_CODE`       | `D`=dev, `Q`=qa, `P`=prod                    | `Q`       |
| `CLOUD`          | `AZ` = Azure                                 | `AZ`      |
| `REGION_CODE`    | `E1`=eastus, `E2`=eastus2, `WE`=westeurope   | `E1`      |
| `ACCESS`         | `E` = External, `I` = Internal               | `E`       |
| `APP_CODE`       | Short application identifier (e.g. `MYAP`)   | `MYAP`    |
| `RESOURCE_TYPE`  | See table below                              | `AP`      |
| `ITERATION`      | `01`, `02`, …                                | `01`      |

**Result:** `BQAZE1EMYAPAP01`

### Resource Type Codes

| Azure Resource                   | Code | Case    | Example                  |
|:-------------------------------- |:---- |:------- |:------------------------ |
| Resource Group                   | `RG` | UPPER   | `BQAZE1EMYAPRG01`        |
| App Service Plan                 | `AP` | UPPER   | `BQAZE1EMYAPAP01`        |
| Key Vault                        | `KV` | UPPER   | `BQAZE1EMYAPKV01`        |
| Application Insights             | `AI` | UPPER   | `BQAZE1EMYAPAI01`        |
| Log Analytics Workspace          | `WS` | UPPER   | `BQAZE1EMYAPWS01`        |
| Logic App Workflow               | `LA` | UPPER   | `BQAZE1EMYAPLA01`        |
| Monitor Action Group             | `AG` | UPPER   | `BQAZE1EMYAPAG01`        |
| Monitor Autoscale Setting        | `AS` | UPPER   | `BQAZE1EMYAPAS01`        |
| Monitor Metric Alert             | `MA` | UPPER   | `BQAZE1EMYAPMA01`        |
| Smart Detector Alert Rule        | `SD` | UPPER   | `BQAZE1EMYAPSD01`        |
| EventGrid System Topic           | `ET` | UPPER   | `BQAZE1EMYAPET01`        |
| Portal Dashboard                 | `PD` | UPPER   | `BQAZE1EMYAPPD01`        |
| API Connection                   | `AC` | UPPER   | `BQAZE1EMYAPAC01`        |
| Web App (Linux)                  | `wa` | **lower** | `bqaze1emyapwa01`      |
| Redis Cache                      | `rc` | **lower** | `bqaze1emyaprc01`      |
| Storage Account                  | `sa` | **lower** | `bqaze1emyapsa01`      |
| Container Registry               | `cr` | **lower** | `bqaze1emyapcr01`      |

> **Why two cases?** Azure imposes lowercase-only restrictions on certain resources (Web Apps, Storage Accounts, Redis Cache). All others may use uppercase. The `common` module handles this automatically via the `resource_types` map.

---

## 4. Module Design Standards

### 4.1 Required File Structure

Every module **must** contain exactly these files:

```text
modules/{resource_name}/
├── main.tf        # Resource declaration only
├── variables.tf   # All input variables with type, description, optional default
└── outputs.tf     # At minimum: id, name
```

A `README.md` is strongly recommended to describe inputs, outputs, and usage examples.

### 4.2 Required Variables (All Modules)

Every module **must** accept these variables:

```hcl
variable "name" {
  type        = string
  description = "Resource name — generated by the common module"
}

variable "location" {
  type        = string
  description = "Azure region (e.g., eastus)"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the Azure Resource Group"
}

variable "environment" {
  type        = string
  description = "Deployment environment: dev | qa | prod"
  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "environment must be dev, qa, or prod"
  }
}

variable "common_tags" {
  type        = map(string)
  description = "Standard tags — always use merge(module.common.tags, { ... })"
  default     = {}
}
```

### 4.3 Required Outputs (All Modules)

Every module **must** expose at minimum:

```hcl
output "id" {
  value       = azurerm_<resource>.<label>.id
  description = "The resource ID"
}

output "name" {
  value       = azurerm_<resource>.<label>.name
  description = "The resource name"
}
```

Expose additional outputs relevant to the resource (e.g., `hostname`, `connection_string`, `vault_uri`). Mark sensitive outputs with `sensitive = true`.

### 4.4 Tagging in Modules

Always use `merge()` in module `main.tf` to combine common tags with resource-specific tags:

```hcl
tags = merge(
  var.common_tags,
  {
    environment = var.environment
  }
)
```

Never hardcode tags inside a module. All tag values come from the calling environment.

### 4.5 No Hard-coded Values in Modules

Modules must be fully parameterised. **Never** hardcode:
- Resource names
- Subscription IDs
- Environment names
- SKU names
- IP addresses or URLs

All such values must be declared as `variables.tf` inputs.

---

## 5. Environment Configuration Standards

### 5.1 Required Files Per Environment Folder

| File                | Purpose                                                  |
|:------------------- |:-------------------------------------------------------- |
| `backend.tf`        | Terraform Cloud workspace binding (`organization`, `workspaces.name`) |
| `providers.tf`      | `azurerm` + `azuread` provider versions, `subscription_id` from common module |
| `common.tf`         | Instantiates `module "common"` and `module "project"`    |
| `locals.tf`         | All environment-specific local values (names, flags, config lookups) |
| `main.tf`           | All module instantiations for this environment            |
| `outputs.tf`        | Key outputs (resource IDs, names, URLs) for cross-reference |
| `resource_group.tf` | Data sources for existing Azure resources (RG, Key Vault, etc.) |

### 5.2 `backend.tf` Standard

```hcl
terraform {
  required_version = "~>1.14.0"
  cloud {
    organization = "{tfc_organization_name}"
    workspaces {
      name = "{bu}-{app_code}-{env}"   # e.g., com-myap-dev, com-myap-qa, com-myap-prod
    }
  }
}
```

### 5.3 `providers.tf` Standard

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.29.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>3.4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = module.common.subscriptions.non_production  # or .production for prod
}

provider "azuread" {}
```

> For **production** environments, use the production subscription output from the `common` module.

### 5.4 `common.tf` Standard

```hcl
module "common" {
  source        = "../../../modules/common"
  app_code      = local.app_code
  business_unit = local.business_unit
  environment   = local.environment
  location      = local.location
  app_name      = local.app_name
}

module "project" {
  source = "../../../modules/project"
}
```

### 5.5 `locals.tf` Standard

```hcl
locals {
  # Identity — always sourced from the project module
  app_code      = module.project.{app_code}.app_code
  business_unit = module.project.{app_code}.business_unit

  # Environment — hardcode only here, never in modules
  environment = "{dev|qa|prod}"
  location    = "eastus"
  app_name    = "{app-name}"

  # Resource names — always from common module
  resource_group_name    = module.common.resource_group_name
  app_service_plan_name  = module.common.app_service_plan_name
  app_service_name       = module.common.web_app_name
  container_registry_name = module.common.container_registry_name

  # Environment-specific config — sourced from project module
  app_service_plan = module.project.{app_code}.app_service.nonprod      # or .prod

  # Existing resources — hardcode names only in locals.tf
  key_vault_name = "{actual-kv-name}"   # Key Vault always pre-exists; never created by Terraform
}
```

### 5.6 `resource_group.tf` Standard

Always use a **data source** for the Resource Group (it pre-exists and is not managed by this repo):

```hcl
data "azurerm_resource_group" "{app_code}_rg" {
  name = local.resource_group_name
}
```

---

## 6. Common & Project Module Responsibilities

This is the single most important architectural boundary. Violations lead to duplication and drift.

### Decision Rule

| Put it in `common` if…                                    | Put it in `project` if…                                    |
|:--------------------------------------------------------- |:---------------------------------------------------------- |
| It is the **same** across all applications                | It **varies** by application or environment                |
| It is a naming / infrastructure concern                   | It is an application / workload concern                    |
| It relates to Azure subscriptions or AD Groups            | It relates to SKU, capacity, or feature flags              |
| Tags shared by all resources                              | App setting keys, CORS config, health check paths          |

### Common Module Owns

- Dynamic resource name generation (all resource types)
- Naming prefix construction (`naming_prefix_upper`, `naming_prefix_lower`)
- AD group names (`AD-SEC-ALL-{BU}-{APPCODE}-ADMINS/DEVELOPERS/USERS`)
- Shared tag structure
- Azure subscription ID mapping

### Project Module Owns

- Per-project, per-environment SKU configuration
- Autoscale thresholds and capacity limits
- App settings keys list (all Key Vault secret key names)
- Portfolio-specific feature toggles
- Region-specific alert thresholds

### Environment Grouping in the Project Module

The project module uses **two keys** to group environment config — not three. This is intentional:

| Key       | Covers               | Rationale                          |
|:--------- |:-------------------- |:---------------------------------- |
| `nonprod` | `dev` **and** `qa`   | Both share the same SKU and config |
| `prod`    | `prod` only          | Production has its own SKU / settings |

The environment folder `locals.tf` selects the correct group:

```hcl
# In infra/envs/dev/{app_code}/locals.tf  OR  infra/envs/qa/{app_code}/locals.tf
app_service_plan = module.project.{app_code}.app_service.nonprod   # dev and qa both use this

# In infra/envs/prod/{app_code}/locals.tf
app_service_plan = module.project.{app_code}.app_service.prod
```

### Example Split

```hcl
# ✅ COMMON module - same for every application (driven by input variables)
naming_prefix_upper = "BQAZE1E{APPCODE}"  # e.g. BQAZE1EMYAP

# ✅ PROJECT module - varies per application and environment
{app_code} = {
  app_code      = "{app_code}"
  business_unit = "{com|glo}"
  app_service = {
    nonprod = { sku = "B1" }    # Used by both dev and qa
    prod    = { sku = "P1v3" }  # Used by prod only
  }
  autoscale = local._autoscale_defaults
}
```

---

## 7. Terraform Cloud Workspace Setup

### Workspace Naming Convention

```
{business_unit}-{app_code}-{environment}
```

| Segment          | Value                                              |
|:---------------- |:-------------------------------------------------- |
| `business_unit`  | Short business unit code (e.g. `com`, `glo`)       |
| `app_code`       | Short application identifier (e.g. `myap`)         |
| `environment`    | `dev`, `qa`, or `prod`                             |

**Examples:**

| Application | Dev               | QA               | Prod               |
|:----------- |:----------------- |:---------------- |:------------------ |
| `myap`      | `com-myap-dev`    | `com-myap-qa`    | `com-myap-prod`    |
| `otherapp`  | `com-otherapp-dev`| `com-otherapp-qa`| `com-otherapp-prod`|

### Workspace Settings (Required)

| Setting                     | Value                                           |
|:--------------------------- |:----------------------------------------------- |
| **Execution Mode**          | `Agent`                                         |
| **Agent Pool**              | The organisation's designated agent pool        |
| **Terraform Version**       | `~>1.14.0` (pin the minor version)              |
| **Working Directory**       | `/infra/envs/{env}/{app_code}`                  |
| **Auto Apply**              | `false` — always require manual plan review     |

### Azure Service Principal (SPN) Per Application

Each Terraform Cloud workspace authenticates to Azure using a **dedicated SPN** scoped to only its own resource group. SPNs must never be shared between applications or environments.

| Rule | Detail |
|:---- |:------ |
| One SPN per application per environment | Limits blast radius if a credential is compromised |
| SPN scoped to the application's Resource Group only | Principle of least privilege |
| SPN credentials stored as TFC workspace variables | `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID` |

---

## 8. CI/CD Pipeline Integration

### GitHub Actions Workflow: `deploy-terraform`

All Terraform runs are triggered via the **`workflow_dispatch`** event (manual trigger). Automatic applies are **not permitted** — every `apply` requires a human to review the `plan` output first.

### Inputs

| Input    | Type   | Description                                     | Default  | Required |
|:-------- |:------ |:----------------------------------------------- |:-------- |:-------- |
| `ENV`    | choice | Target environment: `dev`, `qa`, `prod`         | `qa`     | ✅        |
| `APP`    | choice | Application identifier (e.g. `myap`, `otherapp`)| —        | ✅        |
| `ACTION` | choice | Terraform action: `plan` or `apply`             | `plan`   | ✅        |

### Token Isolation

Each application uses its **own** Terraform Cloud token stored as a GitHub Secret. The workflow selects the correct token based on the `APP` input:

```
{APP_CODE} → secrets.{APP_CODE}_TFE_TOKEN
```

**Never share tokens between applications.** Each token must only have access to that application's workspaces.

### Workflow Execution Flow

```
GitHub Actions (workflow_dispatch)
  │
  ├─ Select TFE Token based on TOWER input
  │
  └─ .github/actions/terraform-deploy
       ├─ terraform init   (using TFC backend)
       ├─ terraform validate
       ├─ terraform plan   (always)
       └─ terraform apply  (only if ACTION=apply AND plan reviewed)
```

---

## 9. Secret & Variable Management

### Rules

| Rule | Enforcement |
|:---- |:----------- |
| **No `terraform.tfvars` files** — ever | Secrets must never be committed to the repository |
| All secrets are stored in **GitHub Actions Secrets** or **Terraform Cloud Workspace Variables** | Only the workflow runner has access at plan/apply time |
| Application secrets (API keys, connection strings) live in **Azure Key Vault** | App Service reads them via Managed Identity references at runtime |
| Key Vault references are built in `locals.tf` — never hardcoded in `main.tf` | Ensures all secret references follow the same pattern |

### Key Vault Reference Pattern

App settings values must always use the Key Vault reference format:

```hcl
# ✅ Correct — Key Vault reference pattern
app_settings = {
  for key in module.project.app_settings_keys : key =>
  "@Microsoft.KeyVault(SecretUri=${data.azurerm_key_vault.key_vault.vault_uri}secrets/${replace(key, "_", "-")}/)"
}

# ❌ Incorrect — plaintext secret in Terraform code
app_settings = {
  MY_API_KEY = "abc123"
}
```

### Key Vault Secret Naming Convention

- App settings use **underscores**: `MY_API_KEY`
- Key Vault secret names use **hyphens**: `MY-API-KEY`
- The `replace(key, "_", "-")` transformation handles this automatically

---

## 10. End-to-End: Adding a New Application

Follow these steps in order when onboarding a new project (tower) into this repository.

### Step 1 — Add Project Config to `project` Module

Open `infra/modules/project/locals.tf` and add a new block:

```hcl
{new_app_code} = {
  app_code      = "{new_app_code}"
  business_unit = "{com|glo}"
  app_service = {
    nonprod = { sku = "B1" }    # Shared by dev and qa
    prod    = { sku = "P1v3" }  # Production only
  }
  autoscale = local._autoscale_defaults
}
```

### Step 2 — Verify Resource Names in `common` Module

Confirm the new `app_code` generates correct names. Preview by inspecting `infra/modules/common/locals.tf` — no changes should be needed as naming is driven by the input variables.

### Step 3 — Create Environment Folders

For each environment (`dev`, `qa`, `prod`):

```bash
mkdir -p infra/envs/{dev,qa,prod}/{new_app_code}
```

Inside each, create all **6 required files** as described in [Section 5](#5-environment-configuration-standards):

```
backend.tf     → Set workspace name: {bu}-{new_app_code}-{env}
providers.tf   → Pin azurerm ~>4.29.0, azuread ~>3.4.0
common.tf      → Instantiate module "common" and module "project"
locals.tf      → Set app_code, environment, resource names
main.tf        → Instantiate all resource modules
outputs.tf     → Expose key outputs
resource_group.tf → Data source for existing RG
```

### Step 4 — Create Terraform Cloud Workspaces

For each environment, create a TFC workspace following the naming convention in [Section 7](#7-terraform-cloud-workspace-setup).

Configure:
- Agent pool: the organisation's designated agent pool
- Working directory: `/infra/envs/{env}/{new_app_code}`
- Execution mode: `Agent`
- Terraform version: `~>1.14.0`

### Step 5 — Create Azure SPN

Create a dedicated Service Principal per tower-environment combination, scoped to the resource group. Store the credentials as Terraform Cloud workspace variables:
- `ARM_CLIENT_ID`
- `ARM_CLIENT_SECRET`
- `ARM_TENANT_ID`
- `ARM_SUBSCRIPTION_ID`

### Step 6 — Add GitHub Secrets

Add a TFC API token for the new tower:

```
{NEWTOWER}_TFE_TOKEN  →  secrets in GitHub repository settings
```

Update the workflow token-selection logic in `.github/workflows/deploy-terraform.yml` to include the new tower.

### Step 7 — Run Plan

```bash
# Validate locally before triggering CI
cd infra/envs/dev/{new_app_code}
terraform init
terraform validate
terraform plan
```

Then trigger the GitHub Actions workflow with `ACTION=plan` for a full CI validation.

### Step 8 — Apply

After plan review, trigger the workflow again with `ACTION=apply`.

---

## 11. End-to-End: Adding a New Module

Follow these steps when a new Azure resource type needs to be managed by Terraform.

### Step 1 — Identify the Resource Type

Identify the `azurerm_*` resource from the Azure Terraform provider:

```
azurerm_redis_cache
azurerm_storage_account
azurerm_application_insights
```

### Step 2 — Add Resource Type Code to `common` Module

Open `infra/modules/common/locals.tf` → `resource_types` map:

```hcl
resource_types = {
  # ... existing entries ...
  redis_cache = { code = "rc", case = "lower" }   # Must be lowercase
  storage_account = { code = "sa", case = "lower" }
  application_insights = { code = "AI", case = "upper" }
}
```

Add the corresponding convenience output to `infra/modules/common/outputs.tf`:

```hcl
output "redis_cache_name" {
  value = local.resource_names.redis_cache
}
```

### Step 3 — Create Module Files

```bash
mkdir -p infra/modules/{resource_name}
touch infra/modules/{resource_name}/main.tf
touch infra/modules/{resource_name}/variables.tf
touch infra/modules/{resource_name}/outputs.tf
```

**`main.tf`** — parameterise every configurable attribute:

```hcl
resource "azurerm_{resource_type}" "{resource_name}" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  # ... resource-specific attributes as variables ...

  tags = merge(
    var.common_tags,
    { environment = var.environment }
  )
}
```

**`variables.tf`** — include all required variables (see [Section 4.2](#42-required-variables-all-modules)) plus resource-specific ones.

**`outputs.tf`** — always output `id` and `name` as minimum (see [Section 4.3](#43-required-outputs-all-modules)).

### Step 4 — Add Project-Level Config (if environment-specific)

If the resource has settings that vary per environment (SKU, tier, capacity), add them to `infra/modules/project/locals.tf`:

```hcl
{app_code} = {
  # ... existing config ...
  redis = {
    nonprod = { sku = "Basic",   capacity = 0, family = "C" }
    prod    = { sku = "Premium", capacity = 2, family = "P" }
  }
}
```

### Step 5 — Instantiate in Environment `main.tf`

```hcl
/* -------------------------------------------------------------------------- */
/*            {Resource Name} Module                                          */
/* -------------------------------------------------------------------------- */
module "{resource_name}" {
  source = "../../../modules/{resource_name}"

  name                = local.{resource_name}_name
  location            = local.location
  resource_group_name = local.resource_group_name
  # ... environment-specific variables from locals ...

  environment = local.environment
  common_tags = merge(module.common.tags, {
    createdby = "terraform"
  })
}
```

And add the name to `locals.tf`:

```hcl
{resource_name}_name = module.common.{resource_name}_name
```

### Step 6 — Validate & Test

```bash
cd infra/envs/qa/{app_code}
terraform init
terraform validate
terraform plan
```

Review the plan output carefully before applying to any environment.

---

## 12. Tagging Standard

All Azure resources **must** carry these tags. They are set in the `common` module and merged in every module:

| Tag Key          | Source                          | Example Value              |
|:---------------- |:------------------------------- |:-------------------------- |
| `project-code`   | `var.app_code`                  | `myap`                     |
| `app-name`       | `var.app_name`                  | `my-application-name`      |
| `environment`    | `var.environment`               | `qa`                       |
| `created-by`     | Hardcoded `terraform`           | `terraform`                |
| `app-version`    | `var.app_version`               | `1.0.0`                    |
| `business-unit`  | `var.business_unit`             | `com`                      |
| `regulatory`     | Set per organisation standard   | *(as required)*            |

Additional resource-level tags (e.g. `purpose`, `shared-across`, `originating-request-number`) are merged at the environment level using `merge(module.common.tags, { ... })`.

---

## 13. Do's and Don'ts

### ✅ Do's

- **Do** create a new module for every distinct Azure resource type.
- **Do** reference resource names exclusively from `module.common` outputs.
- **Do** keep all environment-specific values in `locals.tf` of the env folder.
- **Do** use data sources for pre-existing resources (Resource Groups, Key Vaults).
- **Do** run `terraform validate` and `terraform plan` locally before opening a PR.
- **Do** use `merge(module.common.tags, { ... })` for every resource's tags.
- **Do** mark all sensitive outputs (`connection_string`, `primary_access_key`) as `sensitive = true`.
- **Do** version-pin all provider versions using `~>` (pessimistic constraint).
- **Do** add a `README.md` to every new module describing inputs, outputs, and usage.

### ❌ Don'ts

- **Don't** hardcode resource names, subscription IDs, or secrets inside modules.
- **Don't** create `terraform.tfvars` files — secrets go in Terraform Cloud or GitHub Secrets.
- **Don't** modify the `common` module's naming logic without impact analysis across **all** environments.
- **Don't** use `terraform apply` directly from a developer workstation against non-dev environments.
- **Don't** share TFC tokens between applications.
- **Don't** provision Azure resources manually and then try to import them — plan from IaC first.
- **Don't** store credentials, API keys, or passwords in Terraform state — use Key Vault references.
- **Don't** add environment-specific logic (if/else on `var.environment`) inside modules — keep modules environment-agnostic.

---

## Appendix: Execution Order Reference

When `terraform apply` runs for an environment, the dependency graph resolves in this order:

```
1. module.common       → Generate names, tags, subscriptions
2. module.project      → Load SKU configs, app setting keys
3. data sources        → Read existing Key Vault, Resource Group
4. locals resolution   → Build app_settings KV references, slot configs
5. module.container_registry  → ACR (shared per env)
6. managed identities  → User-assigned identities for ACR pull
7. module.app_service_plan    → Create / update App Service Plan
8. module.app_service         → Create / update Web App with KV references
9. Additional modules  → Storage, monitoring, alerts, event grid, etc.
```

At **App Service startup** (runtime — not Terraform time):

```
10. App Service uses Managed Identity → Authenticates to Key Vault
11. Fetches secret values from Key Vault
12. Sets environment variables
13. Application reads process.env.*
```

---
