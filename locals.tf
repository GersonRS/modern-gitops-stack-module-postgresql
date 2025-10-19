locals {
  credentials = {
    username = "moderngitopsadmin"
    password = resource.random_password.password_secret.result
  }
  databases = concat(["airflow", "jupyterhub", "mlflow", "curated", "feature_store", "litellm"], var.databases)
  helm_values = [{
    postgresql = {
      volumePermissions = {
        enabled = true
      }
      metrics = {
        enabled = var.enable_service_monitor
      }
      global = {
        postgresql = {
          auth = {
            username       = local.credentials.username
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
        debug = var.debug
      }
      primary = {
        initdb = {
          user     = "${local.credentials.username}"
          password = "${local.credentials.password}"
          scripts = {
            "init.sql" = <<-EOT
%{for db in local.databases~}
CREATE DATABASE ${db};
%{endfor~}
CREATE USER ${local.credentials.username}hive WITH PASSWORD 'md5${md5("${local.credentials.password}${local.credentials.username}hive")}';
CREATE DATABASE metastore OWNER ${local.credentials.username}hive;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ${local.credentials.username}hive;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${local.credentials.username}hive;
GRANT USAGE ON SCHEMA public TO ${local.credentials.username}hive;
GRANT ALL PRIVILEGES ON DATABASE metastore TO ${local.credentials.username}hive;
            EOT
          }
        }
        service = {
          type = "ClusterIP"
        }
        persistence = {
          size = "${var.persistence_size}Gi"
        }
        resources = {
          requests = { for k, v in var.resources.requests : k => v if v != null }
          limits   = { for k, v in var.resources.limits : k => v if v != null }
        }
      }
    }
  }]
}
