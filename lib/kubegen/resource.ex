defmodule Kubegen.Resource do
  alias Kubegen.Utils

  @discovery elem(Code.eval_file("build/discovery.ex"), 0)

  def generate(resources, module_prefix) do
    for resource <- resources,
        {gvk, definition} <- get_definitions(resource),
        {module, api_version} = derive_module_and_api_version(module_prefix, gvk),
        generated_resource <- generate_resource(definition, module, api_version) do
      generated_resource
    end
  end

  defp generate_resource(resource_definition, resource_module, api_version) do
    main_resource = do_add_api(api_version, resource_definition, resource_module)

    subresources =
      for subresource_definition <- List.wrap(resource_definition["subresources"]),
          [_, subresource] = String.split(subresource_definition["name"], "/") do
        subresource_resource_module =
          Module.concat(resource_module, String.capitalize(subresource))

        do_add_api(
          api_version,
          subresource_definition,
          subresource_resource_module
        )
      end

    [main_resource | subresources]
  end

  defp do_add_api(api_version, resource_definition, api_module) do
    %{
      "name" => name,
      "verbs" => verbs
    } = resource_definition

    resource_path =
      resource_path(
        api_version,
        resource_definition
      )

    resource_list_path =
      resource_list_path(
        api_version,
        resource_definition
      )

    generator_module =
      if Map.fetch!(resource_definition, "namespaced"),
        do: Kubegen.API.Namespaced,
        else: Kubegen.API.ClusterScoped

    functions =
      verbs
      |> Enum.map(&generator_module.generate_api_for_verb(&1, api_version, name))
      |> Utils.flatten_blocks()
      |> Utils.format_multiline_docs()

    attributes =
      quote do
        @resource_path unquote(resource_path)
        @resource_list_path unquote(resource_list_path)
      end
      |> Utils.flatten_blocks()
      |> Utils.put_newlines()

    req_func =
      quote do
        defp req() do
          Kubeconf.Default
          |> Kubeconf.kubeconf()
          |> Kubereq.new(@resource_path, @resource_list_path)
        end
      end

    ast =
      quote do
        defmodule unquote(api_module) do
          unquote_splicing(attributes)
          unquote(req_func)
          unquote_splicing(functions)
        end
      end

    {api_module, ast}
  end

  defp get_definitions(resource) do
    cond do
      @discovery[resource] ->
        [{resource, @discovery[resource]}]

      File.exists?(resource) ->
        resource
        |> YamlElixir.read_all_from_file!()
        |> Enum.flat_map(&crd_to_gvk_and_discovery/1)

      :otherwise ->
        raise "Resource #{resource} was not found."
    end
  end

  defp crd_to_gvk_and_discovery(crd) do
    %{
      "spec" => %{
        "names" => %{"plural" => name, "kind" => kind},
        "versions" => versions,
        "scope" => scope,
        "group" => group
      }
    } = crd

    namespaced = scope === "Namespaced"

    discovery = %{
      "name" => name,
      "namespaced" => namespaced,
      "verbs" => [
        "create",
        "get",
        "list",
        "delete",
        "deletecollection",
        "update",
        "patch",
        "watch"
      ]
    }

    for version <- versions do
      subresources = Map.keys(version["subresources"] || %{})

      subresource_definitions =
        [
          "status" in subresources &&
            %{
              "name" => "#{name}/status",
              "namespaced" => namespaced,
              "verbs" => ["get", "patch", "update"]
            },
          "scale" in subresources &&
            %{
              "name" => "#{name}/scale",
              "namespaced" => namespaced,
              "verbs" => ["get", "patch", "update"]
            }
        ]
        |> Enum.filter(& &1)

      {"#{group}/#{version["name"]}/#{kind}",
       Map.put(discovery, "subresources", subresource_definitions)}
    end
  end

  defp derive_module_and_api_version(module_prefix, resource) do
    {resource_module_parts, api_version} =
      case String.split(resource, "/") do
        [version, kind] ->
          {["Core", String.capitalize(version), kind], version}

        [api, version, kind] ->
          api_module =
            api
            |> String.split(".")
            |> Enum.map(&String.capitalize/1)
            |> Enum.join("")

          {[api_module, String.capitalize(version), kind], "#{api}/#{version}"}
      end

    resource_module =
      resource_module_parts
      |> then(&[module_prefix | &1])
      |> Module.concat()

    {resource_module, api_version}
  end

  @spec resource_path(api_version :: String.t(), resource_definition :: map()) :: String.t()
  defp resource_path(<<?v, _::integer>> = api_version, resource_definition) do
    do_resource_path("api/#{api_version}", resource_definition)
  end

  defp resource_path(api_version, resource_definition) do
    do_resource_path("apis/#{api_version}", resource_definition)
  end

  @spec do_resource_path(api_version :: String.t(), resource_definition :: map()) :: String.t()
  defp do_resource_path(api_version, %{"name" => resource_name, "namespaced" => true}) do
    "#{api_version}/namespaces/:namespace/#{resource_name}/:name"
  end

  defp do_resource_path(api_version, %{"name" => resource_name, "namespaced" => false}) do
    "#{api_version}/#{resource_name}/:name"
  end

  @spec resource_list_path(api_version :: String.t(), resource_definition :: map()) :: String.t()
  defp resource_list_path(<<?v, _::integer>> = api_version, resource_definition) do
    do_resource_list_path("api/#{api_version}", resource_definition)
  end

  defp resource_list_path(api_version, resource_definition) do
    do_resource_list_path("apis/#{api_version}", resource_definition)
  end

  @spec do_resource_list_path(api_version :: String.t(), resource_definition :: map()) ::
          String.t()
  defp do_resource_list_path(api_version, %{"name" => resource_name, "namespaced" => true}) do
    "#{api_version}/namespaces/:namespace/#{resource_name}"
  end

  defp do_resource_list_path(api_version, %{"name" => resource_name, "namespaced" => false}) do
    "#{api_version}/#{resource_name}"
  end
end
