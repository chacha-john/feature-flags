# Pods get AWS permissions only through IRSA. The app pod itself has none; only the External Secrets
# reader service account can assume a role, and that role can read exactly one secret.

# ---------------------------------------------------------------- IRSA: External Secrets reader
#
# Assumed by the `eso-reader` service account in the app namespace (see kubernetes.tf). It can read
# exactly one secret (the RDS-managed DB credentials) and decrypt it with exactly one key, and only
# when the decrypt request comes through Secrets Manager.

data "aws_iam_policy_document" "eso_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_issuer_host}:sub"
      values   = ["system:serviceaccount:${var.namespace}:eso-reader"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_issuer_host}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "eso_read_db_secret" {
  statement {
    sid = "ReadDatabaseCredentialsSecret"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [var.db_secret_arn]
  }

  statement {
    sid       = "DecryptViaSecretsManagerOnly"
    actions   = ["kms:Decrypt"]
    resources = [var.kms_key_arn]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["secretsmanager.${var.region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eso_reader" {
  name               = "${var.name}-eso-reader"
  assume_role_policy = data.aws_iam_policy_document.eso_trust.json
}

resource "aws_iam_role_policy" "eso_read_db_secret" {
  name   = "read-db-credentials"
  role   = aws_iam_role.eso_reader.id
  policy = data.aws_iam_policy_document.eso_read_db_secret.json
}
