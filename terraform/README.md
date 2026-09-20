# feature-flags on AWS (Terraform)

Infrastructure for the Spring Boot feature-flag service: VPC, EKS, RDS PostgreSQL, IAM, and
Secrets Manager wiring. Replaces `compose.yaml` (`db` -> RDS, `app` -> EKS Deployment,
`nginx` -> internal NLB).

## Layout

```
terraform/
├── environments/
│   └── production/          <- run Terraform here
│       ├── main.tf          composes the modules (the only file that knows how they connect)
│       ├── variables.tf     environment inputs
│       ├── outputs.tf
│       ├── versions.tf      Terraform/provider versions, provider config, (commented) S3 backend
│       ├── terraform.tfvars.example
│       └── k8s/             SecretStore, ExternalSecret, Deployment + Service (applied once)
└── modules/                 reusable, environment-agnostic
    ├── network/             VPC, public/private/database subnets, NAT, routing
    ├── kms/                 customer-managed key (EKS secrets, RDS storage, DB credentials secret)
    ├── eks/                 cluster, node group, add-ons, OIDC/IRSA, cluster + node + CNI roles
    ├── rds/                 PostgreSQL, subnet group, security group, RDS-managed password secret
    └── app/                 namespace, service accounts, ConfigMap, CI RBAC, External Secrets + its IAM role
```

Data flows one way: `network -> kms -> eks -> rds -> app`. A new environment (staging, dr) is a
copy of `environments/production` with different values; the modules are untouched.

| Module | Inputs you will most often change | Key outputs |
|---|---|---|
| `network` | `vpc_cidr`, `az_count`, `single_nat_gateway` | `vpc_id`, `private_subnet_ids`, `database_subnet_ids` |
| `kms` | `name` | `key_arn` |
| `eks` | `kubernetes_version`, `public_access_cidrs`, `node_*` | `cluster_name`, `cluster_security_group_id`, `oidc_provider_arn`, `oidc_issuer_host` |
| `rds` | `instance_class`, `multi_az`, `deletion_protection` | `address`, `secret_arn` |
| `app` | `namespace`, `external_secrets_chart_version` | `eso_reader_role_arn`, `ci_deployer_service_account` |

## How the requirements are met

| Requirement | Where | Detail |
|---|---|---|
| VPC, public + private subnets | `modules/network` | 2-3 AZs. Public (NAT, optional LBs), private (nodes/pods, egress via NAT), database (no internet route). |
| Compute for the container | `modules/eks` | EKS (API-mode access entries, encrypted secrets, control-plane logs), managed node group in private subnets, IMDSv2 only. |
| Managed database, private | `modules/rds` | RDS PostgreSQL 17, private DB subnets, Multi-AZ, encrypted, TLS enforced, reachable only from the EKS node security group on 5432. |
| Least-privilege IAM / RBAC | `modules/eks/iam.tf`, `modules/app` | Explicit actions and ARNs only. IRSA per service account. CI deployer Role: `get/list/watch/patch` on `deployments` in one namespace. |
| Secrets from Secrets Manager | `modules/rds`, `modules/app`, `k8s/` | RDS generates and rotates the master password in Secrets Manager. External Secrets syncs it into the pod at runtime. No password in code, variables, or state. |

## Apply

Prereqs: Terraform >= 1.6, AWS CLI v2 on PATH (used for the EKS auth token), AWS credentials.

```bash
cd environments/production
cp terraform.tfvars.example terraform.tfvars   # set cluster_public_access_cidrs
terraform init
terraform plan -out tfplan
terraform apply tfplan
```

Bootstrap the app once (after `apply`, still in `environments/production`):

```bash
$(terraform output -raw kubeconfig_command)
export AWS_REGION=<region> DB_SECRET_ARN=$(terraform output -raw db_secret_arn) \
       IMAGE=<harbor-host>/<project>/feature-flags:<tag>
for f in secretstore externalsecret deployment; do
  envsubst '${AWS_REGION} ${DB_SECRET_ARN} ${IMAGE}' < k8s/$f.yaml | kubectl apply -f -
done
```

Also create the `harbor-pull` image pull secret in the namespace, and a token for the GitLab
deployer (`kubectl -n feature-flags create token ci-deployer --duration=...`, or use the GitLab
Agent for Kubernetes).

## Things to know

- **AWS-managed policies** are used for the EKS cluster role, node role, and VPC CNI role
  (AmazonEKSClusterPolicy, AmazonEKSWorkerNodePolicy, AmazonEC2ContainerRegistryReadOnly,
  AmazonEKS_CNI_Policy). AWS defines these for EKS and some of their statements use `Resource: "*"`.
- **App connects as the RDS master user** (`flags`), because creating a separate limited DB role
  requires a step inside the database.
- **Password rotation**: RDS rotates the master secret every 7 days. External Secrets refreshes the
  Kubernetes Secret hourly, but running pods keep the old value until restarted. Improvement: Add Stakater
  Reloader (or a scheduled rollout) so pods pick up new credentials.
- **Harbor is on-prem.** Nodes need a network path to it (VPN/Direct Connect via the NAT egress
  IPs) plus the `harbor-pull` secret. Likewise the GitLab runners must reach the EKS API, which is
  why `cluster_public_access_cidrs` is required.
- **The API has no authentication**, so the Service is an internal NLB. Do not expose it publicly
  without adding authN.
- JDBC uses `sslmode=require` (encrypted, no certificate verification). Moving to `verify-full`
  needs the RDS CA bundle inside the image.
