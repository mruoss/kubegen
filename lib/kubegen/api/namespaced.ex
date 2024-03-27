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
      @spec create(resource :: map()) :: Kubereq.response()
      def create(resource) do
        Kubereq.create(req(), resource)
      end
    end
  end

  def generate_api_for_verb("get", api_version, kind) do
    quote do
      @doc """
      Get the resource of kind `#{unquote(kind)}` in apiVersion `#{unquote(api_version)}` by `name`.
      """

      @spec get(namespace :: Kubereq.namespace(), name :: String.t()) ::
              Kubereq.response()
      def get(namespace, name),
        do: Kubereq.get(req(), namespace, name)

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
              namespace :: Kubereq.namespace(),
              name :: String.t(),
              callback :: Kubereq.wait_until_callback()
            ) :: :ok | {:error, :timeout}
      @spec wait_until(
              namespace :: Kubereq.namespace(),
              name :: String.t(),
              callback :: Kubereq.wait_until_callback(),
              timeout :: integer()
            ) :: Kubereq.wait_until_response()
      def wait_until(namespace, name, callback, timeout \\ 10_000),
        do: Kubereq.wait_until(req(), namespace, name, callback, timeout)
    end
  end

  def generate_api_for_verb("list", api_version, kind) do
    quote do
      @doc """
      List resources of kind `#{unquote(kind)}` in apiVersion `#{unquote(api_version)}` in all namespaces.
      """
      @spec list() :: Kubereq.response()
      def list(), do: list(nil, [])

      @doc """
      List resources of kind `#{unquote(kind)}` in apiVersion `#{unquote(api_version)}` in all namespaces.

      ### Options

      * `:field_selectors` - A list of field selectors. See `Kubereq.Step.FieldSelector` for more infos.
      * `:label_selectors` - A list of field selectors. See `Kubereq.Step.LabelSelector` for more infos.
      """
      @spec list(opts :: Keyword.t()) :: Kubereq.response()
      def list(opts) when is_list(opts), do: list(nil, opts)

      @doc """
      List resources of kind `#{unquote(kind)}` in apiVersion
      `#{unquote(api_version)}` in the given `namespace`.

      ### Options

      * `:field_selectors` - A list of field selectors. See `Kubereq.Step.FieldSelector` for more infos.
      * `:label_selectors` - A list of field selectors. See `Kubereq.Step.LabelSelector` for more infos.
      """
      @spec list(namespace :: Kubereq.namespace()) :: Kubereq.response()
      @spec list(namespace :: Kubereq.namespace(), opts :: Keyword.t()) ::
              Kubereq.response()
      def list(namespace, opts \\ []) when is_binary(namespace) or is_nil(namespace),
        do: Kubereq.list(req(), namespace, opts)
    end
  end

  def generate_api_for_verb("delete", api_version, kind) do
    quote do
      @doc """
      Deletes the resource of kind `#{unquote(kind)}` in apiVersion `#{unquote(api_version)}`
      with `name` in `namespace`.
      """
      @spec delete(namespace :: String.t(), name :: Kubereq.namespace()) ::
              Kubereq.response()
      def delete(namespace, name) do
        Kubereq.delete(req(), namespace, name)
      end
    end
  end

  def generate_api_for_verb("deletecollection", api_version, kind) do
    quote do
      @doc """
      Deletes all the resources of kind `#{unquote(kind)}` in apiVersion
      `#{unquote(api_version)}` in `namespace`.

      ### Options

      * `:field_selectors` - A list of field selectors. See `Kubereq.Step.FieldSelector` for more infos.
      * `:label_selectors` - A list of field selectors. See `Kubereq.Step.LabelSelector` for more infos.
      """
      @spec delete_all(namespace :: Kubereq.namespace(), opts :: keyword()) :: Kubereq.response()
      def delete_all(namespace, opts \\ []) do
        Kubereq.delete_all(req(), namespace, opts)
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

      In order to understand `field_manager` and `force`, refer to the
      [Kubernetes documentation about Field Management](https://kubernetes.io/docs/reference/using-api/server-side-apply/#field-management)
      """
      @spec apply(resource :: map()) ::
              Kubereq.response()
      @spec apply(resource :: map(), field_manager :: String.t(), force :: boolean) ::
              Kubereq.response()
      def apply(resource, field_manager \\ "Elixir", force \\ true) do
        Kubereq.apply(req(), resource, field_manager, force)
      end

      @doc """
      Patches the given resource of kind `#{unquote(kind)}` in apiVersion
      `#{unquote(api_version)}` with the given `json_patch`.
      """
      @spec json_patch(
              name :: String.t(),
              namespace :: Kubereq.namespace(),
              json_patch :: map()
            ) :: Kubereq.response()
      def json_patch(name, namespace, json_patch) do
        Kubereq.json_patch(req(), json_patch, namespace, name)
      end

      @doc """
      Patches the given resource of kind `#{unquote(kind)}` in apiVersion
      `#{unquote(api_version)}` with the given `merge_patch`.
      """
      @spec merge_patch(
              name :: String.t(),
              namespace :: Kubereq.namespace(),
              merge_patch :: String.t()
            ) :: Kubereq.response()
      def merge_patch(name, namespace, merge_patch) do
        Kubereq.merge_patch(req(), merge_patch, namespace, name)
      end
    end
  end

  def generate_api_for_verb("watch", api_version, kind) do
    quote do
      @doc """
      Watches for events on all resources of kind `#{unquote(kind)}` in apiVersion
      `#{unquote(api_version)}` in all namespaces.
      """
      @spec watch() :: Kubereq.watch_response()
      def watch(), do: watch(nil, [])

      @doc """
      Watches for events on all resources of kind `#{unquote(kind)}` in apiVersion
      `#{unquote(api_version)}` in all namespaces.

      ### Options

      * `:resource_version` - If given, starts to stream from the given `resourceVersion` of the resource list. Otherwise starts streaming from HEAD.
      * `:stream_to` - If set to a `pid`, streams events to the given pid. If set to `{pid, ref}`, the messages are in the form `{ref, event}`.
      * `:field_selectors` - A list of field selectors. See `Kubereq.Step.FieldSelector` for more infos.
      * `:label_selectors` - A list of field selectors. See `Kubereq.Step.LabelSelector` for more infos.
      """
      @spec watch(opts :: keyword()) :: Kubereq.watch_response()
      def watch(opts) when is_list(opts), do: watch(nil, opts)

      @doc """
      Watches for events on all resources of kind `#{unquote(kind)}` in apiVersion
      `#{unquote(api_version)}` in the given `namespace`.

      ### Options

      * `:resource_version` - If given, starts to stream from the given `resourceVersion` of the resource list. Otherwise starts streaming from HEAD.
      * `:stream_to` - If set to a `pid`, streams events to the given pid. If set to `{pid, ref}`, the messages are in the form `{ref, event}`.
      * `:field_selectors` - A list of field selectors. See `Kubereq.Step.FieldSelector` for more infos.
      * `:label_selectors` - A list of field selectors. See `Kubereq.Step.LabelSelector` for more infos.
      """
      @spec watch(namespace :: Kubereq.namespace(), opts :: keyword()) :: Kubereq.watch_response()
      def watch(namespace, opts \\ []) do
        Kubereq.watch(req(), namespace, opts)
      end

      @doc """
      Watches for events on a single resource of kind `#{unquote(kind)}`
      in apiVersion `#{unquote(api_version)}` in the given `namespace`.

      ### Options

      * `:resource_version` - If given, starts to stream from the given `resourceVersion` of the resource list. Otherwise starts streaming from HEAD.
      * `:stream_to` - If set to a `pid`, streams events to the given pid. If set to `{pid, ref}`, the messages are in the form `{ref, event}`.
      * `:field_selectors` - A list of field selectors. See `Kubereq.Step.FieldSelector` for more infos.
      * `:label_selectors` - A list of field selectors. See `Kubereq.Step.LabelSelector` for more infos.
      """
      @spec watch_single(namespace :: binary(), name :: binary(), opts :: keyword()) ::
              Kubereq.watch_response()
      def watch_single(namespace, name, opts \\ []) do
        Kubereq.watch_single(req(), namespace, name, opts)
      end
    end
  end

  def generate_api_for_verb(_, _, _, _), do: nil
end
