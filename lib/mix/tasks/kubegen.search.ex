defmodule Mix.Tasks.Kubegen.Search do
  @moduledoc ~S"""
  Search Group-Version-Kind (GVK) for Core Resources.
  Kubegen requires you to pass GVK as keys in `config.exs`. This mix tasks
  lets you search for GVK for a specific resource kind.

  ### Example

      mix kubegen.search Pod
  """
  @shortdoc "Search Group-Version-Kind for Core Resources."

  use Mix.Task

  @impl Mix.Task
  def run([input]) do
    discovery = elem(Code.eval_file("build/discovery.ex"), 0)
    gvks = Map.keys(discovery)

    if input in gvks do
      IO.puts(~s'"#{input} is a valid GVK."')
      exit({:shutdown, 0})
    end

    list =
      gvks
      |> Enum.map(fn gvk -> {gvk, String.split(gvk, "/") |> Enum.reverse() |> List.first()} end)
      |> Enum.map(fn {gvk, kind} -> {gvk, kind, String.jaro_distance(input, kind)} end)
      |> Enum.filter(fn {_, _, score} -> score > 0.7 end)
      |> Enum.sort_by(&elem(&1, 2), :desc)
      |> Enum.map(&[IO.ANSI.green(), elem(&1, 0), IO.ANSI.reset(), "\n"])

    case list do
      [] ->
        Owl.IO.puts([
          IO.ANSI.red(),
          "No resource matches your search term."
        ])

      list ->
        Owl.IO.puts([
          "Did you mean one of these?\n\n",
          list
        ])
    end
  end
end
