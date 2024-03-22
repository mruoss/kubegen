defmodule Kubegen.API.ClusterScoped do
  @moduledoc false

  @spec generate_api_for_verb(
          verb :: String.t(),
          api_version :: String.t(),
          kind :: String.t()
        ) :: Macro.t()
  def generate_api_for_verb("create", api_version, kind) do
    quote do
      @doc """
      Create a resource of kind `#{unquote(kind)}` in apiVersion
      `#{unquote(api_version)}.`
      """
      @spec create(resource :: map()) :: Kubereq.Client.Req.response()
      def create(resource),
        do: Client.create(req(), @resource_list_path, resource)
    end
  end

  def generate_api_for_verb("get", api_version, kind) do
    quote do
      @doc """
      Get the resource of kind `#{unquote(kind)}` in apiVersion
      `#{unquote(api_version)}` by `name`.
      """
      @spec get(name :: map()) :: Kubereq.Client.Req.response()
      def get(name),
        do: Client.get(req(), @resource_path, nil, name)

      @doc """
      Wait until the given `callback` returns true for a resource of kind
      #{unquote(kind)} in apiVersion `#{unquote(api_version)}`

      ### Callback Args and Result

      The given `callback` is called with the resource as argument. If the resource
      was deleted, `:deleted` is passed as argument.
      The callback should return a boolean.

      ### Options

      * `timeout` - Timeout in ms after function terminates with `{:error, :timeout}`.
        Defaults to `10_000`.

      """
      @spec wait_until(name :: String.t(), callback :: Client.wait_until_callback()) ::
              :ok | {:error, timeout}
      @spec wait_until(
              name :: String.t(),
              callback :: Client.wait_until_callback(),
              timeout :: integer()
            ) :: :ok | {:error, timeout}
      def wait_until(name, callback, timeout \\ 10_000),
        do:
          Client.wait_until(
            req(),
            @resource_list_path,
            nil,
            name,
            callback,
            timeout
          )
    end
  end

  def generate_api_for_verb("list", api_version, kind) do
    quote do
      @doc """
      List resources of kind `#{unquote(kind)}` in apiVersion
      `#{unquote(api_version)}`.
      """
      @spec list() :: Kubereq.Client.Req.response()
      @spec list(opts :: keyword()) :: Kubereq.Client.Req.response()
      def list(opts \\ []), do: Client.list(req(), @resource_list_path, nil, opts)
    end
  end

  def generate_api_for_verb("delete", api_version, kind) do
    quote do
      @doc """
      Deletes the resource of kind `#{unquote(kind)}` in apiVersion
      `#{unquote(api_version)}` with `name`.
      """
      @spec delete(name :: String.t()) :: Kubereq.Client.Req.response()
      def delete(name) do
        Client.delete(req(), @resource_path, nil, name)
      end
    end
  end

  def generate_api_for_verb("deletecollection", api_version, kind) do
    quote do
      @doc """
      Deletes all the resources of kind `#{unquote(kind)}` in apiVersion
      `#{unquote(api_version)}`.
      """
      @spec delete_all() :: Kubereq.Client.Req.response()
      def delete_all() do
        Client.delete_all(req(), @resource_list_path, nil)
      end
    end
  end

  def generate_api_for_verb("update", api_version, kind) do
    quote do
      @doc """
      Updates the given resource of kind `#{unquote(kind)}` in apiVersion
      `#{unquote(api_version)}`.
      """
      @spec update(resource :: map()) :: Kubereq.Client.Req.response()
      def update(resource) do
        Client.update(req(), @resource_path, resource)
      end
    end
  end

  def generate_api_for_verb("patch", api_version, kind) do
    quote do
      @doc """
      Server-Side applies the given resources of kind `#{unquote(kind)}` in apiVersion
      `#{unquote(api_version)}`.

      In order to understand `fieldManager` and `force`, refer to the
      [Kubernetes documentation about Field Management](https://kubernetes.io/docs/reference/using-api/server-side-apply/#field-management)
      """
      @spec apply(update :: map()) :: Kubereq.Client.Req.response()
      @spec apply(update :: map(), field_manager :: String.t(), force :: boolean()) ::
              Kubereq.Client.Req.response()
      def apply(resource, field_manager \\ "Elixir", force \\ true) do
        Client.apply(req(), @resource_path, resource, field_manager, force)
      end

      @doc """
      Patches the given resource of kind `#{unquote(kind)}` in apiVersion
      `#{unquote(api_version)}` with the given `json_patch`.
      """
      @spec json_patch(name :: String.t(), json_patch :: map()) ::
              Kubereq.Client.Req.response()
      def json_patch(name, json_patch) do
        Client.json_patch(req(), @resource_path, json_patch, nil, name)
      end

      @doc """
      Patches the given resource of kind `#{unquote(kind)}` in apiVersion
      `#{unquote(api_version)}` with the given `merge_patch`.
      """
      @spec merge_patch(name :: String.t(), merge_patch :: map()) ::
              Kubereq.Client.Req.response()
      def merge_patch(name, merge_patch) do
        Client.merge_patch(req(), @resource_path, merge_patch, nil, name)
      end
    end
  end

  def generate_api_for_verb("watch", api_version, kind) do
    quote do
      @doc """
      Watches for events on resources of kind `#{unquote(kind)}` in apiVersion
      `#{unquote(api_version)}`.
      """
      @spec watch() :: Kubereq.Client.Req.response()
      @spec watch(opts :: keyword()) :: Kubereq.Client.Req.response()
      def watch(opts \\ []) do
        Client.watch(req(), @resource_list_path, nil, opts)
      end
    end
  end

  def generate_api_for_verb(_, _, _, _), do: nil
end
