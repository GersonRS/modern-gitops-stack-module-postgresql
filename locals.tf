locals {
  credentials = {
    admin    = "postgres"
    user     = "moderngitopsadmin"
    password = resource.random_password.password_secret.result
  }
  databases = concat(["airflow", "jupyterhub", "mlflow", "curated", "feature_store", "metastore"], var.databases)
  helm_values = [{
    postgresql = {
      volumePermissions = {
        enabled = true
      }
      metrics = {
        enabled = false
      }
      global = {
        postgresql = {
          auth = {
            username       = local.credentials.user
            database       = "keycloak"
            existingSecret = "postgresql-secrets"
            secretKeys = {
              adminPasswordKey       = "postgres-password"
              userPasswordKey        = "password"
              replicationPasswordKey = "replication-password"
            }
          }
        }
      }
      image = {
        debug = true
      }
      primary = {
        initdb = {
          scripts = {
            "init.sql" = <<-EOT
              %{for db in local.databases~}
CREATE DATABASE ${db};
              %{endfor~}
            EOT
          }
        }
        service = {
          type = "LoadBalancer"
        }
        persistence = {
          size = "20Gi"
        }
      }
    }
  }]
}
