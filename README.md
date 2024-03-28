# Kubegen

Generate resource based Kubernetes clients with `Kubegen`.

[![Module Version](https://img.shields.io/hexpm/v/kubegen.svg)](https://hex.pm/packages/kubegen)
[![Last Updated](https://img.shields.io/github/last-commit/mruoss/kubegen.svg)](https://github.com/mruoss/kubegen/commits/main)

[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/kubegen/)
[![Total Download](https://img.shields.io/hexpm/dt/kubegen.svg)](https://hex.pm/packages/kubegen)
[![License](https://img.shields.io/hexpm/l/kubegen.svg)](https://github.com/mruoss/kubegen/blob/main/LICENSE.md)

## Installation

`kubegen` is a code generator. Add the package as dev dependency. Make sure to  
add `kubereq` to your list of dependencies as well:

```elixir
def deps do
  [
    {:kubegen, "~> 0.1.0", only: :dev, runtime: false},
    {:kubereq, "~> 0.1.0"}
  ]
end
```

The docs can be found at <https://hexdocs.pm/kubegen>.

## Configuration

Before you can generate clients, you need to create a configuration in your
`config.exs` under `config :kubegen, :default` or `config :kubegen, :mycluster`.
where a custom `:mycluster` identifier is passed as argument
(`mix kubegen -c mycluster`)

- `:module_prefix` - The prefix of the generated modules (e.g. `MyApp.K8sClient`)
- `:kubeconfig_pipeline` - The `Pluggable` pipeline responsible for loading the Kubernetes config. (e.g. `Kubereq.Kubeconfig.Default`)
- `:resources` - List of resources for which clients are generated.

The entries of `:resources` can be in the form of

- Group-Version-Kind in the case of Kubernetes core resources.
- Path to a local CRD YAML (multiple CRDs in one file are supported)
- URL to a public remote CRD Yaml (multiple CRDs in one file are supported)

### Example

```ex
config :kubegen, :default,
  module_prefix: MyApp.K8sClient,
  kubeconfig_pipeline: Kubereq.Kubeconfig.Default,
  resources: [
    "v1/ConfigMap",
    "rbac.authorization.k8s.io/v1/ClusterRole",
    "test/support/foos.example.com.yaml", # local CRD
    "https://raw.githubusercontent.com/mruoss/kompost/main/priv/manifest/postgresdatabase.crd.yaml" # public remote CRD
  ]
```

### How to find the correct Group-Version-Kind identifier

Use `mix kubegen.search` to search for GVKs (e.g. `mix.kubegen.search Pod`)

### Generate Resource Clients

Now you can (re-)generate clients using `mix kubegen` or `mix kubegen -c mycluster`
