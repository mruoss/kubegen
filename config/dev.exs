import Config

config :kubegen, :default,
  module_prefix: Kubegen.K8s.Client,
  resources: [
    "v1/ConfigMap",
    "rbac.authorization.k8s.io/v1/ClusterRole"
  ]
