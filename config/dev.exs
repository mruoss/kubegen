import Config

config :kubegen, :default,
  module_prefix: Kubegen.K8sClient,
  kubeconfig_pipeline: Kubereq.Kubeconfig.Default,
  resources: [
    "v1/ConfigMap",
    "rbac.authorization.k8s.io/v1/ClusterRole",
    "test/support/foos.example.com.yaml",
    "v1/Namespace",
    "https://raw.githubusercontent.com/mruoss/kompost/main/priv/manifest/postgresdatabase.crd.yaml"
  ]
