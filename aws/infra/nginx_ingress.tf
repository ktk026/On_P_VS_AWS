resource "terraform_data" "nginx_ingress" {
  input = {
    manifest_url = "https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/aws/deploy.yaml"
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${self.input.manifest_url}"

    interpreter = ["C:\\Windows\\System32\\cmd.exe", "/C"]
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete -f ${self.input.manifest_url} --ignore-not-found=true --wait=false --timeout=60s || exit /b 0"

    interpreter = ["C:\\Windows\\System32\\cmd.exe", "/C"]
  }

  depends_on = [
    terraform_data.update_kubeconfig
  ]
}
