# ChatOpsBot : Streamlined Cloud Operations via Slack

**Serverless, Chat-Native, CI-driven**

Traditionally, responding to an AWS incident means jumping between the AWS Console, CloudWatch, and Slack — slowing down mean-time-to-recovery and requiring broad console access for every engineer. This project brings AWS operations directly into Slack: alerts arrive in-channel the moment something breaks, and approved engineers can inspect state, check logs, and trigger remediation without ever leaving chat. It follows the **Operational Excellence Pillar** of the AWS Well-Architected Framework — every action is scoped by IAM, every infrastructure change goes through CI review, and Terraform state is locked so no two applies can collide.

<img width="899" height="423" alt="slackAWS drawio (2)" src="https://github.com/user-attachments/assets/f44db3a3-16d5-496d-b97f-87059640bdbe" />


## Architecture overview

**1. Detection → Alert (fully automated)**

```
CloudWatch Alarm → EventBridge → SNS → AWS Chatbot → Slack Channel
```

CloudWatch continuously watches Lambda error rates. The moment a threshold is crossed, EventBridge routes the state change to SNS, which AWS Chatbot is subscribed to — Chatbot formats and posts the alert directly into Slack, with a link back to the console.

**2. Diagnose → Remediate → Verify (chat-native, via AWS Chatbot)**

```
Slack (@aws command) → AWS Chatbot → AWS API (Lambda / CloudWatch / Logs) → Slack (result)
```

From the same Slack channel, an engineer can run scoped AWS CLI-style commands directly — inspect the alarm, pull recent logs, invoke the remediation Lambda, and confirm recovery — all via AWS Chatbot's native command support, no custom Slack app or slash-command backend required.

**3. Status dashboard (independent, pull-based)**

```
Browser → CloudFront → S3 (static site) → app.js fetch → API Gateway → status Lambda → CloudWatch
```

A static HTML/CSS/JS dashboard, served over HTTPS via CloudFront, polls a small API Gateway + Lambda endpoint every 30 seconds to show live alarm state — independent of Slack, for anyone who wants a glance without opening chat.

---

## To recreate this architecture

| Layer | Service | Purpose |
|---|---|---|
| Detection | Amazon CloudWatch | Alarms on Lambda `Errors` metric |
| Routing | Amazon EventBridge | Forwards alarm state changes to SNS |
| Messaging | Amazon SNS | Pub/sub fan-out to AWS Chatbot |
| Chat integration | AWS Chatbot | Posts alerts to Slack; runs scoped AWS commands from Slack |
| Compute | AWS Lambda (Python 3.12) | `restart_function` (remediation), `check_logs` (diagnostics), `status` (health check) |
| Access control | AWS IAM | Least-privilege roles scoped to `chatopsbot-*` resources only |
| Dashboard hosting | Amazon S3 + CloudFront (OAC) | Static frontend, privately sourced, publicly served over HTTPS |
| Dashboard data | Amazon API Gateway (HTTP API) | Exposes the `status` Lambda to the browser |
| IaC | Terraform (modular) | Remote state in S3, locked via DynamoDB |
| CI/CD | GitHub Actions | `fmt` → `validate` → `tfsec` → `plan` (PR) → manual approval → `apply` (main), via OIDC |

---

## Security model

- **IAM roles scoped to `chatopsbot-*` resources only** — no Lambda in this project can touch, invoke, or modify anything outside its own naming prefix, even though some granted actions (like `lambda:UpdateFunctionConfiguration`) sound broad in isolation.
- **`cloudwatch:DescribeAlarms` is the one action granted with `resources = ["*"]`** — this specific AWS action does not support resource-level ARN scoping, so wildcarding it is the only valid option, not a scoping shortcut.
- **S3 buckets are fully private.** The dashboard bucket is reachable only through CloudFront, enforced via **Origin Access Control (OAC)** — the current AWS-recommended replacement for the older OAI pattern.
- **GitHub Actions authenticates via OIDC** — no long-lived AWS access keys stored anywhere. A federated IAM role trusts only this exact workflow file in this exact repo (`job_workflow_ref`-scoped), and issues short-lived credentials per run.
- **Manual approval gate before `apply`** — a GitHub Environment with required reviewers sits between `plan` and `apply`, so no infrastructure change reaches AWS without a human clicking approve.
- **No GitHub Secrets are needed for AWS authentication** — this is a deliberate property of the OIDC setup, not an oversight.

---

## Project structure

```
chatopsbot/
├── bootstrap/                 # one-time: S3 state bucket, DynamoDB lock table, GitHub OIDC + IAM role
├── environments/
│   └── dev/
│       ├── backend.tf           # remote state config (S3 + DynamoDB lock)
│       ├── main.tf               # wires all modules together
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars       # gitignored — Slack IDs live here
├── modules/
│   ├── iam/                          # least-privilege roles for Lambda + Chatbot
│   ├── lambda/                          # restart_function, check_logs, status
│   ├── monitoring/                          # CloudWatch alarm + EventBridge routing
│   ├── notifications/                          # SNS topic + AWS Chatbot Slack config
│   └── dashboard/                                  # S3 + CloudFront + API Gateway
├── src/
│   ├── lambda/                                        # Python source per function
│   └── dashboard/                                        # index.html, style.css, app.js
├── .github/
│   └── workflows/
│       └── terraform.yml                                    # CI: fmt, validate, tfsec, plan, approval-gated apply
└── .gitignore
```

## Tech stack

- **Terraform** ≥ 1.5 with the `hashicorp/aws` provider (~> 5.0)
- **AWS**: Lambda, CloudWatch, EventBridge, SNS, Chatbot, IAM (OIDC), S3, CloudFront, API Gateway, DynamoDB
- **CI/CD**: GitHub Actions, authenticated via OIDC, with a manual approval gate before `apply`
- **Frontend**: vanilla HTML/CSS/JS (no framework — kept intentionally simple for a status page)

---

## Troubleshooting log

Real issues hit while building this, kept here for reference:

1. **Dashboard fetch failed to parse URL**

   - **Issue:** `app.js` still contained the placeholder string `<your-api-id>.execute-api.<region>...` instead of the real API Gateway endpoint, producing `Failed to parse URL from https://.execute-api..amazonaws.com/status`.
   - **Fix:** Replaced the placeholder with the actual `terraform output dashboard_api_endpoint` value, then re-applied so the `aws_s3_object` resource (keyed on `filemd5`) picked up the content change and re-uploaded the file.

2. **Stale content served after a fix**

   - **Issue:** Even after fixing and re-uploading `app.js`, the dashboard kept showing old behavior.
   - **Fix:** CloudFront caches origin content by default. Needed a hard browser refresh to see the update.

3. **API returned `{"message":"Internal Server Error"}` with no useful detail**

   - **Issue:** The `status` Lambda's execution role had no `cloudwatch:DescribeAlarms` permission. CloudWatch Logs showed the real `AccessDenied` traceback that API Gateway had swallowed into a generic 500.
   - **Fix:** Added a dedicated IAM statement granting `cloudwatch:DescribeAlarms` with `resources = ["*"]`

4. **Alarm never fired despite repeatedly invoking the Lambda with bad input**

   - **Issue:** The Lambda's input validation used `return {"statusCode": 400, ...}` instead of raising an exception. CloudWatch's `Errors` metric only counts **unhandled exceptions** — a function that runs successfully and returns an error-shaped payload does not count as an error.
   - **Fix:** Invoked the Lambda with a payload that caused a genuine unhandled exception (a nonexistent target function name, causing `boto3` itself to raise `ResourceNotFoundException`) to reliably trigger the alarm for testing.

5. **tfsec: Lambda functions flagged for missing tracing**

   - **Issue:** `aws-lambda-enable-tracing` (LOW severity) fired on every Lambda resource.
   - **Fix:** Adding `tracing_config { mode = "Active" }` to each `aws_lambda_function` block, enabling X-Ray tracing — genuinely useful for tracing a request across API Gateway → Lambda → CloudWatch during a real incident, not just a lint fix.

---

## Infrastructure verification

### 1. Live incident: alarm fires, posts to Slack
<img width="780" height="721" alt="Screenshot 2026-07-17 at 3 05 51 PM" src="https://github.com/user-attachments/assets/6f8d7dc0-24f1-4c5e-9ba0-ffaf738dd4fa" />


### 2. Diagnosing from Slack (`@aws cloudwatch describe-alarms`)


<img width="540" height="889" alt="Screenshot 2026-07-17 at 3 33 49 PM" src="https://github.com/user-attachments/assets/7c163989-fcc8-4fa9-9d76-a85af2c01409" />

### 3. Remediation triggered from Slack (`@aws lambda invoke`)

<img width="553" height="834" alt="Screenshot 2026-07-17 at 3 43 43 PM" src="https://github.com/user-attachments/assets/cad0f907-6c6f-44f6-9543-34e9329534df" />


### 4. Alarm returns to OK

<img width="555" height="773" alt="Screenshot 2026-07-17 at 3 46 49 PM" src="https://github.com/user-attachments/assets/d3da1126-2d49-4525-9449-3597bbf2f129" />


### 5. Live dashboard showing real-time status

<img width="1827" height="379" alt="Screenshot 2026-07-17 at 3 02 32 PM" src="https://github.com/user-attachments/assets/7619bcef-2125-47fe-8af6-33119f469a46" />

<img width="1844" height="410" alt="Screenshot 2026-07-17 at 3 00 58 PM" src="https://github.com/user-attachments/assets/70fbd234-ef8b-42da-832b-97ed0e3cd0b6" />


### 6. CI pipeline: plan → manual approval gate → apply

<img width="1121" height="619" alt="Screenshot 2026-07-18 at 12 47 34 AM" src="https://github.com/user-attachments/assets/fdbfd17a-27c6-485c-8f73-28c413ec3d56" />

<img width="836" height="512" alt="Screenshot 2026-07-18 at 1 29 53 AM" src="https://github.com/user-attachments/assets/bc12c5ce-b5b8-4cf3-9dae-961b76d55ebd" />



---

## Getting started

### Prerequisites

- [Terraform CLI](https://developer.hashicorp.com/terraform/install) ≥ 1.5
- An AWS account with programmatic access configured (`aws configure`)
- A Slack workspace where you can authorize AWS Chatbot
- A GitHub repository with Actions enabled

### 1. Bootstrap the remote state backend + OIDC (one-time, local)

```bash
cd bootstrap
terraform init
terraform apply
```

This creates the S3 state bucket, DynamoDB lock table, GitHub OIDC provider, and the IAM role GitHub Actions assumes. Note the `github_actions_role_arn` output.

### 2. Authorize Slack with AWS Chatbot (one-time, manual — console only)

AWS Chatbot's Slack OAuth handshake can't be scripted. Do this once in the AWS Console (Chatbot → Configure new client → Slack), then note the workspace ID and channel ID.

### 3. Set your variables

Create `environments/dev/terraform.tfvars` (gitignored):

```hcl
slack_workspace_id = "T0123ABCDE"
slack_channel_id   = "C0123ABCDE"
```

### 4. Deploy

```bash
cd environments/dev
terraform init         # connects to the remote backend
terraform validate      # check for syntax errors
terraform plan            # preview what will be created — review carefully
terraform apply             # build the infrastructure
```

### 5. Get your outputs

```bash
terraform output
```

Paste `dashboard_api_endpoint` into `src/dashboard/app.js`'s `API_ENDPOINT` constant, then re-apply so Terraform re-uploads the updated file.

### 6. Set up CI

- Add the `github_actions_role_arn` output value into `.github/workflows/terraform.yml`'s `role-to-assume` field
- Add `SLACK_WORKSPACE_ID` and `SLACK_CHANNEL_ID` as GitHub Actions secrets
- Create a `production` GitHub Environment with required reviewers, to enforce manual approval before `apply`
- Push to GitHub — PRs trigger `plan`; merges to `main` trigger `plan` → wait for approval → `apply`

### 7. Tear it down

```bash
terraform destroy   # deletes environments/dev resources; bootstrap/ can stay for reuse
```

---

## Terraform command reference

| Command | Description |
|---|---|
| `terraform init` | Download providers and connect to remote backend |
| `terraform validate` | Check for syntax errors |
| `terraform plan` | Preview changes — no cost, no risk |
| `terraform apply` | Build the infrastructure in AWS |
| `terraform output` | Show outputs after deploy |
| `terraform fmt` | Auto-format all `.tf` files |
| `terraform destroy` | Delete all infrastructure |

---

## Credits
Architecture inspired by Lucy Wang

---
## License

MIT — use this as a learning reference or a starting point for your own ChatOps setup.
