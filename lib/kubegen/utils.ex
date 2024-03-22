defmodule Kubegen.Utils do
  @spec put_newlines(Macro.t()) :: Macro.t()
  def put_newlines({term, metadata, arguments}) do
    end_of_expression =
      Keyword.get(metadata, :end_of_expression, [])
      |> Keyword.put(:newlines, 2)

    {term, Keyword.put(metadata, :end_of_expression, end_of_expression), arguments}
  end

  def put_newlines([node]), do: [put_newlines(node)]
  def put_newlines([head | tail]), do: [head | put_newlines(tail)]

  @doc """
  Walks the given AST and replaces `@doc` and `@moduledoc` strings with `\"\"\"` blocks if the
  contents have newlines
  """
  @spec format_multiline_docs(Macro.t()) :: Macro.t()
  def format_multiline_docs(ast_node) do
    pre = fn
      {:"::", [],
       [
         {{:., [], [Kernel, :to_string]}, [from_interpolation: true], [contents]},
         {:binary, [], _module}
       ]},
      acc ->
        {contents, acc}

      ast_node, acc ->
        {ast_node, acc}
    end

    post = fn
      {:doc, meta, [{:<<>>, [], contents}]}, acc ->
        {{:doc, meta,
          [
            {:__block__, [delimiter: "\"\"\"", indentation: 2], [Enum.join(contents)]}
          ]}, acc}

      {:moduledoc, meta, [contents]} = node, acc ->
        if is_binary(contents) and String.contains?(contents, "\n") do
          {{:moduledoc, meta, [{:__block__, [delimiter: "\"\"\"", indentation: 2], [contents]}]},
           acc}
        else
          {node, acc}
        end

      ast_node, acc ->
        {ast_node, acc}
    end

    {ast_node, _acc} = Macro.traverse(ast_node, nil, pre, post)
    ast_node
  end

  def flatten_blocks(ast) do
    for single_ast <- List.wrap(ast),
        {:__block__, [], blocks} = single_ast,
        block <- blocks do
      block
    end
  end
end
