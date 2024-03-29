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

## Using the generated Clients

`kubegen` creates a module per resource and subresource. Each resource is
generaated with functions for the operations applicable to that resource. The
generated functions also come with `@doc` documentations.

### ConfigMap Example

You can use `apply/3` or `create/2` to create a new resource:

```ex
import YamlElixir.Sigil
alias MyApp.K8sClient.Core.V1.ConfigMap

ConfigMap.apply(~y"""
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: default
  name: my-config
  labels:
    app: my-app
data:
  foo: bar
""")
```

To retrieve a resource, use `get/2`:

```ex
ConfigMap.get("default", "my-config")
```

Use `list/0` or `list/1` to list resources of that kind in all namespaces or
`list/2` to list resources in a specific namespace. Label or field selectors can
be passed as option if needed.

```ex
ConfigMap.list("default", label_selectors: [{"app", "my-app"}])
```

`delete/2` and `delete_all/2` delete a single or multiple resources (whereas the
latter also supports selectors).

```ex
ConfigMap.delete("default", "my-config")
ConfigMap.delete_all("default", label_selectors: [{"app", "my-app"}])
```

There are more functions like `update/1`, `json_path/3`, `merge_patch/3`,
`watch/N`, `watch_single/3` `wait_until/4`. Checkout the generated modules for
their documentation.
