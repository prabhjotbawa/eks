output "addon_version" {
  value       = data.aws_eks_addon.pod_identity_agent.addon_version
  description = "Boolean indicating whether the Pod Identity Agent is installed"
}