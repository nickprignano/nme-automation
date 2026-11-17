---
status: proposed
date: 2026-11-17
decision-makers: [maintainers]
---

# 0037. Azure DevOps Pipelines as an optional CI/CD backend alongside GitHub Actions

## Context and Problem Statement

The gated deploy pipeline ([0016](0016-gated-deploy-pipeline.md), [0033](0033-ci-cd-reusable-stage-pr-plans-drift.md))
assumes GitHub Actions, GitHub Environments for required-reviewer approvals, and a GitHub App for
the setup chatbot. As the kit expands to Azure Government ([0034](0034-azure-government-cloud-parameter.md))
and Azure Local (`modules/azure-local`), two gaps appear: GitHub's required-reviewer gate on private
repositories requires a paid GitHub plan, and many Azure-first or regulated enterprises standardize
on Azure DevOps (or self-hosted Azure DevOps Server) rather than GitHub.com. How should the kit add
Azure DevOps Pipelines as an optional CI/CD provider without weakening the external approval gate,
adding stored Azure secrets, or overstating Azure Government compliance?

## Considered Options

- Keep GitHub Actions as the only supported CI/CD platform (Azure Gov / private-repo customers use Cloud Shell directly)
- Add Azure DevOps Pipelines (`ci_provider = "azure_devops"`) as a first-class optional backend sharing `scripts/pipeline/stage.sh` and the Azure Storage `plans` / `answers` contract
- Support arbitrary CI/CD systems (GitLab, Bitbucket, Terraform Cloud) via generic webhooks

## Decision Outcome

Chosen option: "Add Azure DevOps Pipelines (`ci_provider = \"azure_devops\"`) as a first-class optional backend",
because Azure DevOps fits the Azure-first preference ([0009](0009-prefer-azure-github-hashicorp-oss.md)),
supports Entra Workload Identity Federation (OIDC) and Environment approval gates, and reuses the
kit's existing Azure Storage `plans` and `answers` state contract.

### Proposed Spec

- **CI-agnostic stage runner (`scripts/pipeline/stage.sh`):**
  - Detect the runner via `GITHUB_ACTIONS=true` vs `TF_BUILD=True`.
  - Guard `::add-mask::`, `GITHUB_STEP_SUMMARY`, and `GITHUB_OUTPUT` so they run only under GitHub Actions.
  - On Azure Pipelines (`TF_BUILD=True`), emit outputs via `##vso[task.setvariable variable=...;isOutput=true]`
    (`plan_blob`, `plan_sha256`, `changes`) and fall back `run_dir` to `${BUILD_BUILDID}-${SYSTEM_JOBATTEMPT}`.
  - Keep all summary/result JSON output redacted via `redact` and stored in the `plans` blob container.
- **Azure Pipelines YAML (`azure-pipelines/`):**
  - `stage.yml` (template): mirrors `.github/workflows/stage.yml`, running `stage.sh plan` in `<env>-plan`
    and `stage.sh apply` as a deployment job targeting `<env>-apply` (where the ADO Environment
    approval check and `refs/heads/main` branch control live).
  - `deploy.yml`: manual/chatbot-triggered parameters (`environment`, `stage`, `apply`, `destroy`, `allow_replace`)
    plus optional GitOps auto-plan/gated-apply on `main`.
  - `pr-plan.yml` and `drift.yml`: opt-in same-repo PR plan comment and scheduled drift check.
- **Bootstrap and identity (`modules/deploy-pipeline`, `scripts/pipeline/bootstrap.sh`):**
  - Add `ci_provider = "github" | "azure_devops"` (default `"github"`).
  - Under `azure_devops`, create the `<env>-plan` and `<env>-apply` Entra user-assigned identities
    with ADO Workload Identity Federation (`issuer = https://vstoken.dev.azure.com/<ado_org_id>`,
    `subject = sc://<org>/<project>/<service-connection>`), two ADO Service Connections, and two
    ADO Environments (required reviewer + `refs/heads/main` branch check on `<env>-apply`).
- **Self-hosted VNet / Azure Local agent (`modules/vnet-runner`):**
  - Support `ci_provider = "azure_devops"` using an ephemeral `azp-agent` Azure Container Apps Job
    with KEDA's `azure-pipelines` scaler (instead of `github-runner`) so plans/applies can reach
    private endpoints and Azure Local clusters.
- **Setup chatbot (`assistant/pipeline.py`):**
  - Extract a `PipelineBackend` interface (`GitHubBackend` | `AzureDevOpsBackend`).
  - `AzureDevOpsBackend` triggers pipeline runs via the ADO Pipelines REST API using the chatbot's
    **Entra Managed Identity** token (`499b84ac-1321-427f-aa17-267ca6975798/.default`)—no PAT, no
    Key Vault signing key, and no `/setup/github` App manifest flow.
  - Parameterize `ado_base_url` (default `https://dev.azure.com`) so a customer-operated **Azure DevOps Server**
    inside an Azure Government VNet can use the same backend.

### Consequences

- Good, because private-repo and Azure-first organizations get gated `plan` → approval → `apply`
  without a paid GitHub plan or a stored PAT/secret.
- Good, because `stage.sh` and the `plans`/`answers` blob contract remain single-source-of-truth.
- Bad, because `dev.azure.com` itself runs in Microsoft's **commercial cloud**, not inside Azure Government;
  pipeline YAML, logs, and approval clicks still traverse commercial SaaS unless the customer hosts
  **Azure DevOps Server** inside their Azure Government VNet.
- Bad, because it adds a second CI YAML surface, `azuredevops` provider/CLI bootstrap path, and
  KEDA scaler configuration to test and maintain.

## More Information

### Red-Team Checklist (for review before implementation)

1. **Azure Government control-plane boundary:** Make explicit in `docs/government.md` and `docs/pipeline.md`
   that `dev.azure.com` is outside the Azure Government boundary; strict FedRAMP High / IL4–IL5
   "all-in-Gov" boundaries require either customer-hosted Azure DevOps Server (via `ado_base_url`)
   or direct Cloud Shell deployment.
2. **Cross-cloud WIF mismatch:** An ADO org backed by a commercial Entra tenant cannot issue WIF
   tokens accepted by an Azure Government subscription's Entra tenant. Bootstrap must detect and
   warn on tenant/cloud mismatches rather than failing obscurely at first run.
3. **Chatbot self-approval prevention:** Unlike a GitHub App (which cannot be an environment reviewer),
   an Entra Managed Identity *can* be added to ADO Approvers or Project Administrators. Bootstrap must
   grant the chatbot's MI only `Queue builds` / `View build pipeline` and assert it is not an Approver
   or Administrator on `<env>-apply`.
4. **Log masking parity:** `##vso[task.setvariable ...;issecret=true]` does not retroactively mask
   arbitrary stdout the same way `::add-mask::` does; `stage.sh` must continue redacting GUIDs from
   all summaries and avoid printing raw IDs.
5. **Azure Local reachability:** Cloud-hosted ADO agents cannot reach private Azure Local clusters;
   `modules/vnet-runner` (or an Arc-enabled local agent) is required when `azure_local` is enabled.
6. **Bootstrap auth in Cloud Shell:** Verify `az account get-access-token --resource 499b84ac-1321-427f-aa17-267ca6975798`
   works cleanly for `azuredevops` provider/CLI bootstrap without asking the user to paste a PAT.
