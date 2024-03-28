defmodule Mix.Tasks.Kubegen do
  @moduledoc ~S"""
  (Re-)Generates clients for Kubernetes resources according to the config.

  ## Configuration

  Prior to running this Mix task, you need to create a configuration in your
  `config.exs` under `config :kubegen, :default` or `config :kubegen, :mycluster`.
  where a custom `:mycluster` identifier is passed as argument
  (`mix kubegen -c mycluster`)

  * `:module_prefix` - The prefix of the generated modules (e.g. `MyApp.K8sClient`)
  * `:kubeconfig_pipeline` -  The `Pluggable` pipeline responsible for loading the Kubernetes config. (e.g. `Kubereq.Kubeconfig.Default`)
  * `:resources` - List of resources for which clients are generated.

  The entries of `:resources` can be in the form of

  * Group-Version-Kind in the case of Kubernetes core resources.
  * Path to a local CRD YAML (multiple CRDs in one file are supported)
  * URL to a public remote CRD Yaml (multiple CRDs in one file are supported)

  ### Example

  ```
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

  """
  @shortdoc "(Re-)generates Kubernetes Clients"

  alias Kubegen.Resource

  use Mix.Task

  @cli_opts [strict: [cluster: :string], aliases: [c: :cluster]]

  @impl Mix.Task
  def run(args) do
    {parsed, argv, _errors} = OptionParser.parse(args, @cli_opts)

    if length(argv) != 0, do: usage_and_exit()

    cluster = String.to_atom(parsed[:cluster] || "default")
    config = Application.get_env(:kubegen, cluster)

    if is_nil(config[:module_prefix]) do
      Owl.IO.puts([
        IO.ANSI.red(),
        ":module_prefix (Module prefix) not set. Please set the module prefix in config.exs under :kubegen, #{inspect(cluster)}, :prefix.",
        IO.ANSI.reset(),
        ~s'''


        Example:

        config :kubegen, #{inspect(cluster)},
          module_prefix: #{app_module()}.K8sClient
        '''
      ])

      exit({:shutdown, 65})
    end

    if is_nil(config[:kubeconfig_pipeline]) do
      Owl.IO.puts([
        IO.ANSI.red(),
        ":kubeconfig_pipeline (Kubeconfig Loader Pipeline) is not set. Please define the module defining a Pluggable pipeline for loading the Kubernetes configuration.",
        IO.ANSI.reset(),
        ~s'''


        Example:

        config :kubegen, #{inspect(cluster)},
        kubeconfig_pipeline: Kubereq.Kubeconfig.Default
        '''
      ])

      exit({:shutdown, 65})
    end

    if is_nil(config[:resources]) do
      Owl.IO.puts([
        IO.ANSI.red(),
        ":resources (List of resoures) is not set. Please define the list of resources to be generated in config.exs under :kubegen, #{inspect(cluster)}, :resources.",
        IO.ANSI.reset(),
        ~s'''


        Example:

        config :kubegen, #{inspect(cluster)},
          resources: [
            "v1/Pod",
            "apps/v1/Deployment"
          ]
        '''
      ])

      exit({:shutdown, 65})
    end

    module_prefix = config[:module_prefix]
    kubeconfig_pipeline = config[:kubeconfig_pipeline]
    resources = config[:resources] |> Enum.uniq()

    "lib/#{Macro.underscore(module_prefix)}/*"
    |> Path.wildcard()
    |> Enum.each(&File.rm_rf!/1)

    for {module_name, ast} <- Resource.generate(resources, module_prefix, kubeconfig_pipeline) do
      rendered =
        ast
        |> Code.quoted_to_algebra(escape: false, locals_without_parens: [step: 1, step: 2])
        |> Inspect.Algebra.format(98)

      file_path = Path.join("lib", "#{Macro.underscore(module_name)}.ex")
      file_path |> Path.dirname() |> File.mkdir_p!()
      File.write(file_path, rendered)

      Owl.IO.puts([
        "Generated module ",
        IO.ANSI.green(),
        "#{module_name}",
        IO.ANSI.reset(),
        " in file ",
        IO.ANSI.yellow(),
        file_path,
        IO.ANSI.reset()
      ])
    end
  end

  defp usage_and_exit() do
    IO.puts("""
    mix kubegen_resource [-c cluster]

    cluster      Cluster identifier as used in config.exs (defaults to :default)

    """)

    exit({:shutdown, 65})
  end

  defp app_module() do
    Macro.camelize("#{Mix.Project.config()[:app]}")
  end
end
