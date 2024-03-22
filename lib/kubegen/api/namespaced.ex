defmodule Kubegen.API.Namespaced do
  @moduledoc false

  @spec generate_api_for_verb(
          verb :: String.t(),
          api_version :: String.t(),
          kind :: String.t()
        ) :: Macro.t()
  def generate_api_for_verb("create", api_version, kind) do
    quote do
      @doc """
      Create a resource of kind `#{unquote(kind)}` in apiVersion `#{unquote(api_version)}`.
      """
      @spec create(resource :: map()) :: Kubereq.Client.Req.response()
      def create(resource) do
        Client.create(req(), @resource_list_path, resource)
      end
    end
  end

  def generate_api_for_verb("get", api_version, kind) do
    quote do
      @doc """
      Get the resource of kind `#{unquote(kind)}` in apiVersion `#{unquote(api_version)}` by `name`.
      """

      @spec get(namespace :: Client.namespace(), name :: String.t()) ::
              Kubereq.Client.Req.response()
      def get(namespace, name),
        do: Client.get(req(), @resource_path, namespace, name)

      @doc """
      Wait until the given `callback` resolves to true for a resource of kind
      `#{unquote(kind)}` in apiVersion #{unquote(api_version)}.

      ### Callback Args and Result

      The given `callback` is called with the resource as argument. If the resource
      was deleted, `:deleted` is passed as argument.
      The callback should return a boolean.

      ### Options

      * `timeout` - Timeout in ms after function terminates with `{:error, :timeout}`.
        Defaults to `10_000`.

      """
      @spec wait_until(
              namespace :: Client.namespace(),
              name :: String.t(),
              callback :: Client.wait_until_callback()
            ) :: :ok | {:error, timeout}
      @spec wait_until(
              namespace :: Client.namespace(),
              name :: String.t(),
              callback :: Client.wait_until_callback(),
              timeout :: integer()
            ) :: :ok | {:error, timeout}
      def wait_until(namespace, name, callback, timeout \\ 10_000),
        do:
          Client.wait_until(
            req(),
            @resource_list_path,
            namespace,
            name,
            callback,
            timeout
          )
    end
  end

  def generate_api_for_verb("list", api_version, kind) do
    quote do
      @doc """
      List resources of kind `#{unquote(kind)}` in apiVersion `#{unquote(api_version)}` in all namespaces.
      """
      @spec list() :: Kubereq.Client.Req.response()
      def list(), do: list(nil, [])

      @spec list(opts :: Keyword.t()) :: Kubereq.Client.Req.response()
      def list(opts) when is_list(opts), do: list(nil, opts)

      @doc """
      List resources of kind `#{unquote(kind)}` in apiVersion
      `#{unquote(api_version)}` in the given `namespace`.
      """
      @spec list(namespace :: Client.namespace()) :: Kubereq.Client.Req.response()
      @spec list(namespace :: Client.namespace(), opts :: Keyword.t()) ::
              Kubereq.Client.Req.response()
      def list(namespace, opts \\ []) when is_binary(namespace) or is_nil(namespace),
        do: Client.list(req(), @resource_list_path, namespace, opts)
    end
  end

  def generate_api_for_verb("delete", api_version, kind) do
    quote do
      @doc """
      Deletes the resource of kind `#{unquote(kind)}` in apiVersion `#{unquote(api_version)}`
      with `name` in `namespace`.
      """
      @spec delete(name :: String.t(), namespace :: Client.namespace()) ::
              Kubereq.Client.Req.response()
      def delete(name, namespace) do
        Client.delete(req(), @resource_path, namespace, name)
      end
    end
  end

  def generate_api_for_verb("deletecollection", api_version, kind) do
    quote do
      @doc """
      Deletes all the resources of kind `#{unquote(kind)}` in apiVersion
      `#{unquote(api_version)}` in `namespace`.
      """
      @spec delete_all(namespace :: Client.namespace()) :: Kubereq.Client.Req.response()
      def delete_all(namespace) do
        Client.delete_all(req(), @resource_list_path, namespace)
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

      In order to understand `field_manager` and `force`, refer to the
      [Kubernetes documentation about Field Management](https://kubernetes.io/docs/reference/using-api/server-side-apply/#field-management)
      """
      @spec apply(resource :: map()) ::
              Kubereq.Client.Req.response()
      @spec apply(resource :: map(), field_manager :: String.t(), force :: boolean) ::
              Kubereq.Client.Req.response()
      def apply(resource, field_manager \\ "Elixir", force \\ true) do
        Client.apply(req(), @resource_path, resource, field_manager, force)
      end

      @doc """
      Patches the given resource of kind `#{unquote(kind)}` in apiVersion
      `#{unquote(api_version)}` with the given `json_patch`.
      """
      @spec json_patch(
              name :: String.t(),
              namespace :: Client.namespace(),
              json_patch :: map()
            ) :: Kubereq.Client.Req.response()
      def json_patch(json_patch, namespace, name) do
        Client.json_patch(req(), @resource_path, json_patch, namespace, name)
      end

      @doc """
      Patches the given resource of kind `#{unquote(kind)}` in apiVersion
      `#{unquote(api_version)}` with the given `merge_patch`.
      """
      @spec merge_patch(
              name :: String.t(),
              namespace :: Client.namespace(),
              merge_patch :: map()
            ) :: Kubereq.Client.Req.response()
      def merge_patch(merge_patch, namespace, name) do
        Client.merge_patch(req(), @resource_path, merge_patch, namespace, name)
      end
    end
  end

  def generate_api_for_verb("watch", api_version, kind) do
    quote do
      @doc """
      Watches for events on resources of kind `#{unquote(kind)}` in apiVersion
      `#{unquote(api_version)}` in all namespaces.
      """
      def watch(opts) when is_list(opts), do: watch(nil, opts)

      @doc """
      Watches for events on resources of kind `#{unquote(kind)}` in apiVersion
      `#{unquote(api_version)}` in the given `namespace`.
      """
      def watch(namespace, opts \\ []) when is_binary(namespace) or is_nil(namespace) do
        Client.watch(req(), @resource_list_path, namespace, opts)
      end
    end
  end

  def generate_api_for_verb(_, _, _, _), do: nil
end
