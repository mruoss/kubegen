defmodule Mix.Tasks.Kubegen do
  @moduledoc """
  (Re-)Generates clients for Kubernetes resources according to the config.
  """
  @shortdoc "(Re-)generates Kubernetes Clients"

  alias Kubegen.Resource

  use Mix.Task

  @cli_opts [strict: [cluster: :string], aliases: [c: :cluster]]

  @impl Mix.Task
  def run(args) do
    {parsed, argv, _errors} = OptionParser.parse(args, @cli_opts)

    if length(argv) != 0, do: usage_and_exit()

    cluster = parsed[:cluster] || "default" |> String.to_atom()
    config = Application.get_env(:kubegen, cluster)

    if is_nil(config[:module_prefix]) do
      Owl.IO.puts([
        IO.ANSI.red(),
        "Module prefix not set. Please set the moduel prefix in config.exs under :kubegen, #{inspect(cluster)}, :prefix.",
        IO.ANSI.reset(),
        ~s'''


        Example:

        config :kubegen, #{inspect(cluster)},
          module_prefix: #{app_module()}.K8sClient
        '''
      ])

      exit({:shutdown, 65})
    end

    if is_nil(config[:resources]) do
      Owl.IO.puts([
        IO.ANSI.red(),
        "List of resoures not set. Please define the list of resources to be generated in config.exs under :kubegen, #{inspect(cluster)}, :resources.",
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
    resources = config[:resources] |> Enum.uniq()

    "lib/#{Macro.underscore(module_prefix)}/*"
    |> Path.wildcard()
    |> Enum.map(&File.rm_rf!/1)

    for {module_name, ast} <- Resource.generate(resources, module_prefix) do
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
