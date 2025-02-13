locals {
  credentials = {
    admin    = "postgres"
    user     = "moderngitopsadmin"
    password = resource.random_password.password_secret.result
  }
  databases = concat(["airflow", "jupyterhub", "mlflow", "curated", "feature_store"], var.databases)
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
CREATE USER ${local.credentials.user}hive WITH PASSWORD 'md5${md5(local.credentials.password)}${local.credentials.user}hive';
CREATE DATABASE metastore OWNER ${local.credentials.user}hive;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ${local.credentials.user}hive;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${local.credentials.user}hive;
GRANT USAGE ON SCHEMA public TO ${local.credentials.user}hive;
GRANT ALL PRIVILEGES ON DATABASE metastore TO ${local.credentials.user}hive;
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
