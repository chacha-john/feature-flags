# In-cluster building blocks that must exist before the app is deployed. The Deployment itself is
# rolled out by the GitLab pipeline (`kubectl set image`), and the manifests in environments/production/k8s bootstrap it.

resource "kubernetes_namespace_v1" "app" {
  metadata {
    name = var.namespace

    labels = {
      "pod-security.kubernetes.io/enforce"         = "restricted"
      "pod-security.kubernetes.io/enforce-version" = "latest"
    }
  }
}

# Identity the app pod runs as. It needs neither the Kubernetes API nor AWS, so no token is mounted.
resource "kubernetes_service_account_v1" "app" {
  metadata {
    name      = "feature-flags"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
  }

  automount_service_account_token = false
}

# Identity External Secrets uses to read the DB credentials from Secrets Manager (IRSA).
resource "kubernetes_service_account_v1" "eso_reader" {
  metadata {
    name      = "eso-reader"
    namespace = kubernetes_namespace_v1.app.metadata[0].name

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.eso_reader.arn
    }
  }
}

# Non-secret connection settings. The username and password come from Secrets Manager, not from here.
resource "kubernetes_config_map_v1" "app" {
  metadata {
    name      = "feature-flags-config"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
  }

  data = {
    SPRING_PROFILES_ACTIVE = "postgres"
    SPRING_DATASOURCE_URL  = "jdbc:postgresql://${var.db_address}:${var.db_port}/${var.db_name}?sslmode=require"
  }
}

# ---------------------------------------------------------------- CI deployer (least privilege)
#
# Matches what .gitlab-ci.yml does: `kubectl get/annotate/set image` on the Deployment and
# `rollout status`. One namespace, one resource type, four verbs.

resource "kubernetes_service_account_v1" "ci_deployer" {
  metadata {
    name      = "ci-deployer"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
  }

  automount_service_account_token = false
}

resource "kubernetes_role_v1" "ci_deployer" {
  metadata {
    name      = "ci-deployer"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments"]
    verbs      = ["get", "list", "watch", "patch"]
  }
}

resource "kubernetes_role_binding_v1" "ci_deployer" {
  metadata {
    name      = "ci-deployer"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.ci_deployer.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.ci_deployer.metadata[0].name
    namespace = kubernetes_namespace_v1.app.metadata[0].name
  }
}

# ---------------------------------------------------------------- External Secrets Operator
#
# Syncs the Secrets Manager secret into a Kubernetes Secret at runtime. Only the controller is
# installed here; the SecretStore/ExternalSecret objects live in environments/production/k8s (they need the CRDs first).

resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = var.external_secrets_chart_version
  namespace        = "external-secrets"
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }
}
