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
      Kubereq.Client.resource_path(
        api_version,
        resource_definition
      )

    resource_list_path =
      Kubereq.Client.resource_list_path(
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
      [
        if Enum.any?(verbs, &(&1 in ["get", "delete", "update", "patch"])) do
          quote do: @resource_path(unquote(resource_path))
        end,
        if Enum.any?(verbs, &(&1 in ["create", "get", "list", "deletecollection", "watch"])) do
          quote do: @resource_list_path(unquote(resource_list_path))
        end
      ]
      |> Enum.filter(& &1)
      |> Utils.put_newlines()

    use_stmt =
      quote(do: use(Kubereq))
      |> Utils.put_newlines()

    steps =
      quote do
        step Kubeconf.ENV
        step Kubeconf.File, path: ".kube/config", relative_to_home?: true
        step Kubeconf.ServiceAccount
      end
      |> Utils.flatten_blocks()

    aliases =
      quote(do: alias(Kubereq.Client))
      |> Utils.put_newlines()

    ast =
      quote do
        defmodule unquote(api_module) do
          unquote(use_stmt)

          unquote(aliases)

          unquote_splicing(attributes)

          unquote_splicing(steps)

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

    namespaced = scope === "namespaced"

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
end
