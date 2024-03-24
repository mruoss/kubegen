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
      @spec create(resource :: map()) :: Kubereq.response()
      def create(resource),
        do: Kubereq.create(req(), resource)
    end
  end

  def generate_api_for_verb("get", api_version, kind) do
    quote do
      @doc """
      Get the resource of kind `#{unquote(kind)}` in apiVersion
      `#{unquote(api_version)}` by `name`.
      """
      @spec get(name :: String.t()) :: Kubereq.response()
      def get(name),
        do: Kubereq.get(req(), nil, name)

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
      @spec wait_until(name :: String.t(), callback :: Kubereq.wait_until_callback()) ::
              :ok | {:error, timeout}
      @spec wait_until(
              name :: String.t(),
              callback :: Kubereq.wait_until_callback(),
              timeout :: integer()
            ) :: :ok | {:error, timeout}
      def wait_until(name, callback, timeout \\ 10_000),
        do:
          Kubereq.wait_until(
            req(),
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
      @spec list() :: Kubereq.response()
      @spec list(opts :: keyword()) :: Kubereq.response()
      def list(opts \\ []), do: Kubereq.list(req(), nil, opts)
    end
  end

  def generate_api_for_verb("delete", api_version, kind) do
    quote do
      @doc """
      Deletes the resource of kind `#{unquote(kind)}` in apiVersion
      `#{unquote(api_version)}` with `name`.
      """
      @spec delete(name :: String.t()) :: Kubereq.response()
      def delete(name) do
        Kubereq.delete(req(), nil, name)
      end
    end
  end

  def generate_api_for_verb("deletecollection", api_version, kind) do
    quote do
      @doc """
      Deletes all the resources of kind `#{unquote(kind)}` in apiVersion
      `#{unquote(api_version)}`.
      """
      @spec delete_all() :: Kubereq.response()
      def delete_all() do
        Kubereq.delete_all(req(), nil)
      end
    end
  end

  def generate_api_for_verb("update", api_version, kind) do
    quote do
      @doc """
      Updates the given resource of kind `#{unquote(kind)}` in apiVersion
      `#{unquote(api_version)}`.
      """
      @spec update(resource :: map()) :: Kubereq.response()
      def update(resource) do
        Kubereq.update(req(), resource)
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
      @spec apply(update :: map()) :: Kubereq.response()
      @spec apply(update :: map(), field_manager :: String.t(), force :: boolean()) ::
              Kubereq.response()
      def apply(resource, field_manager \\ "Elixir", force \\ true) do
        Kubereq.apply(req(), resource, field_manager, force)
      end

      @doc """
      Patches the given resource of kind `#{unquote(kind)}` in apiVersion
      `#{unquote(api_version)}` with the given `json_patch`.
      """
      @spec json_patch(name :: String.t(), json_patch :: map()) ::
              Kubereq.response()
      def json_patch(name, json_patch) do
        Kubereq.json_patch(req(), json_patch, nil, name)
      end

      @doc """
      Patches the given resource of kind `#{unquote(kind)}` in apiVersion
      `#{unquote(api_version)}` with the given `merge_patch`.
      """
      @spec merge_patch(name :: String.t(), merge_patch :: String.t()) ::
              Kubereq.response()
      def merge_patch(name, merge_patch) do
        Kubereq.merge_patch(req(), merge_patch, nil, name)
      end
    end
  end

  def generate_api_for_verb("watch", api_version, kind) do
    quote do
      @doc """
      Watches for events on resources of kind `#{unquote(kind)}` in apiVersion
      `#{unquote(api_version)}`.
      """
      @spec watch() :: Kubereq.watch_response()
      @spec watch(opts :: keyword()) :: Kubereq.watch_response()
      def watch(opts \\ []) do
        Kubereq.watch(req(), nil, opts)
      end

      @doc """
      Watches for events on a single resource of kind `#{unquote(kind)}` in apiVersion
      `#{unquote(api_version)}`.
      """
      @spec watch_single(name :: String.t(), opts :: keyword()) :: Kubereq.watch_response()
      def watch_single(name, opts) do
        Kubereq.watch_single(req(), nil, name, opts)
      end
    end
  end

  def generate_api_for_verb(_, _, _, _), do: nil
end
