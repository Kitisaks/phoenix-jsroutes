defmodule PhoenixJsroutes.UrlTransformer do
  @moduledoc false

  @doc """
  Transforms a Phoenix route path into a JavaScript template-literal expression.
  """
  def to_js(path) when is_binary(path) do
    chunks = transform(path, [])
    IO.iodata_to_binary(["`", Enum.reverse(chunks), "`"])
  end

  defp transform("", acc), do: acc

  defp transform(<<":", rest::binary>>, acc) do
    {var, rest} = take_var(rest, [])
    transform(rest, [["${", Enum.reverse(var), "}"] | acc])
  end

  defp transform(<<char::utf8, rest::binary>>, acc) do
    transform(rest, [escape_static(<<char::utf8>>) | acc])
  end

  defp take_var(<<>>, var), do: {var, ""}
  defp take_var(<<"/", _::binary>> = rest, var), do: {var, rest}

  defp take_var(<<char::utf8, rest::binary>>, var) do
    take_var(rest, [<<char::utf8>> | var])
  end

  defp escape_static("\\"), do: "\\\\"
  defp escape_static("`"), do: "\\`"
  defp escape_static("$"), do: "\\$"
  defp escape_static(char), do: char
end
