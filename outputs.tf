output "id" {
  description = "ID to pass other modules in order to refer to this module as a dependency."
  value       = resource.null_resource.this.id
}

output "credentials" {
  value = local.credentials
}

output "cluster_dns" {
  description = "Postgres cluster dns"
  value       = "postgresql.postgresql.svc.cluster.local"
}
output "cluster_ip" {
  description = "Postgres Cluster IPs"
  value       = data.kubernetes_service.postgresql.spec[0].cluster_ip
}

output "external_ip" {
  description = "Postgres External IPs"
  value       = data.kubernetes_service.postgresql.status[0].load_balancer[0].ingress[0].ip
}

output "airflow_fernetKey" {
  description = "Airflow FrenetKey to this database"
  value       = resource.random_password.airflow_fernetKey.result
}

output "airflow_fernetKey" {
  description = "LITELLM SALT KEY to this database"
  value       = resource.random_password.litellm_salt_key.result
}
