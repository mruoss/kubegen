import Config

config :kubegen, :default,
  module_prefix: Kubegen.K8sClient,
  resources: [
    "v1/ConfigMap",
    "rbac.authorization.k8s.io/v1/ClusterRole",
    "test/support/foos.example.com.yaml"
  ]
