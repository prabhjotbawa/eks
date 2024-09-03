resource "helm_release" "external_nginx" {
  name = "external"

  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress"
  create_namespace = true
  version          = "4.10.1"

  timeout = 120

  values = [file("${path.module}/values/nginx-ingress.yml")]

  depends_on = [helm_release.aws_lbc]
}