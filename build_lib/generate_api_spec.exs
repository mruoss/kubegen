Mix.install([:jason])
discovery_path = "build_lib/kubernetes/api/discovery/"
out_path = "build/discovery.ex"

format_api_resource_list = fn api_resource_list_file ->
  api_resource_list = api_resource_list_file |> File.read!() |> Jason.decode!()

  for main_resource <- Enum.reject(api_resource_list["resources"], &String.contains?(&1["name"], "/")) do
    prefix = "#{main_resource["name"]}/"

    subresources =
      Enum.filter(api_resource_list["resources"], fn
        %{"name" => <<^prefix::binary, subresource::binary>>} ->
          subresource not in ["exec", "proxy", "attach", "log", "portforward"]

        _ ->
          false
      end)

    Map.put(main_resource, "subresources", subresources)
  end
end

core_api = discovery_path |> Path.join("api.json") |> File.read!() |> Jason.decode!()

core_apis =
  for version <- core_api["versions"],
      filename = Path.join(discovery_path, "api__#{version}.json"),
      api_resource <- format_api_resource_list.(filename),
      into: %{} do
    {"#{version}/#{api_resource["kind"]}", api_resource}
  end

api_groups = discovery_path |> Path.join("apis.json") |> File.read!() |> Jason.decode!()

extended_apis =
  for api_group <- api_groups["groups"],
      version <- api_group["versions"],
      filename =
        Path.join(discovery_path, "apis__#{api_group["name"]}__#{version["version"]}.json"),
      api_resource <- format_api_resource_list.(filename),
      into: %{} do
    {"#{api_group["name"]}/#{version["version"]}/#{api_resource["kind"]}", api_resource}
  end



discovery = Map.merge(core_apis, extended_apis)
File.write!(out_path, inspect(discovery, printable_limit: :infinity, limit: :infinity))
