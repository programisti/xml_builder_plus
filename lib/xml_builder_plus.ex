defmodule XmlBuilderPlus do
  @moduledoc """
  A module for generating XML

  ## Examples

      iex> XmlBuilderPlus.doc(:person, [])
      "<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\" ?>\\n<person/>"

      iex> XmlBuilderPlus.doc(:person, "Josh", [])
      "<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\" ?>\\n<person>Josh</person>"

      iex> XmlBuilderPlus.element(:person, "Josh") |> XmlBuilderPlus.generate([])
      "<person>Josh</person>"

      iex> XmlBuilderPlus.element(:person, %{occupation: "Developer"}, "Josh") |> XmlBuilderPlus.generate([])
      "<person occupation=\\\"Developer\\\">Josh</person>"
  """

  # namespace = %{tag: 'ns', excluded_nodes: ['Envelope', 'Header', 'Body'] }

  def doc(name, attrs, content, namespace_list),do: [:_doc_type | [element(name, attrs, content)]] |> generate(namespace_list)
  def doc(name, attrs_or_content, namespace_list),do: [:_doc_type | [element(name, attrs_or_content)]] |> generate(namespace_list)
  def doc(name_or_tuple, nil), do: doc(name_or_tuple, [])
  def doc(name_or_tuple, namespace_list \\ []), do: [:_doc_type | tree_node(name_or_tuple) |> List.wrap] |> generate(namespace_list)


  def element(name) when is_bitstring(name) or is_atom(name),
    do: element({name})

  def element(list) when is_list(list),
    do: Enum.map(list, &element/1)

  def element({name}),
    do: element({name, nil, nil})

  def element({name, attrs}) when is_map(attrs),
    do: element({name, attrs, nil})

  def element({name, content}),
    do: element({name, nil, content})

  def element({name, attrs, []}) when is_map(attrs) do
    element({name, attrs, nil})
  end

  def element({name, attrs, []})  do
    element({name, attrs, nil})
  end
  def element({name, attrs, content}) when is_list(content) do
    {name, attrs, Enum.map(content, &tree_node/1)}
  end
  def element({name, attrs, content}),
    do: {name, attrs, content}

  def element(name, attrs) when is_map(attrs),
    do: element({name, attrs, nil})

  def element(name, content),
    do: element({name, nil, content})

  def element(name, attrs, content),
    do: element({name, attrs, content})

  def generate(:_doc_type, 0) do
    ~s|<?xml version="1.0" encoding="UTF-8" ?>|
  end

  def generate(:_doc_type, 0, namespace, _) when is_list(namespace) do
    ~s|<?xml version="1.0" encoding="UTF-8" ?>|
  end

  def generate(any, namespace) when is_list(namespace) do
    generate(any, 0, namespace, "")
  end
  def generate(any, namespace) when is_map(namespace) do
    generate(any, 0, Map.to_list(namespace), "")
  end

  def generate(list, level, namespace, old_namespace) when is_list(list) and is_list(namespace) do
    list |> Enum.map(&(generate(&1, level, namespace, old_namespace))) |> Enum.intersperse("\n") |> Enum.join
  end
  def generate({name, attrs, content}, level, namespace, old_namespace) when (attrs == nil or map_size(attrs) == 0) and (content==nil or (is_list(content) and length(content)==0)) do
    ns = namespace[name] || old_namespace
    "#{indent(level)}<#{ns}#{name}/>"
  end
  def generate({name, attrs, content}, level, namespace, old_namespace) when content==nil or (is_list(content) and length(content)==0) do
    ns = namespace[name] || old_namespace
    "#{indent(level)}<#{ns}#{name} #{generate_attributes(attrs)}/>"
  end
  def generate({name, attrs, content}, level, namespace, old_namespace) when (attrs == nil or map_size(attrs) == 0) and not is_list(content) do
    ns = namespace[name] || old_namespace
    "#{indent(level)}<#{ns}#{name}>#{generate_content(content, level+1, namespace, ns)}</#{ns}#{name}>"
  end
  def generate({name, attrs, content}, level, namespace, old_namespace) when (attrs == nil or map_size(attrs) == 0) and is_list(content) do
    ns = namespace[name] || old_namespace
    "#{indent(level)}<#{ns}#{name}>#{generate_content(content, level+1, namespace, ns)}\n#{indent(level)}</#{ns}#{name}>"
  end
  def generate({name, attrs, content}, level, namespace, old_namespace) when map_size(attrs) > 0 and not is_list(content)  do
    ns = namespace[name] || old_namespace
    "#{indent(level)}<#{ns}#{name} #{generate_attributes(attrs)}>#{generate_content(content, level+1, namespace, ns)}</#{ns}#{name}>"
  end
  def generate({name, attrs, content}, level, namespace, old_namespace) when map_size(attrs) > 0 and is_list(content) do
    ns = namespace[name] || old_namespace
    "#{indent(level)}<#{ns}#{name} #{generate_attributes(attrs)}>#{generate_content(content, level+1, namespace, ns)}\n#{indent(level)}</#{ns}#{name}>"
  end


  defp generate_content(children, level, namespace, old_namespace) when is_list(children) and is_list(namespace) do
    "\n" <> Enum.map_join(children, "\n", &(generate(&1, level, namespace, old_namespace)))
  end

  defp generate_content(content, _level, namespace, old_namespace) when is_list(namespace) do
    escape(content)
  end
  defp generate_attributes(attrs) do
    Enum.map_join(attrs, " ", fn {k,v} -> "#{k}=#{quote_attribute_value(v)}" end)
  end
  defp tree_node(element_spec),
    do: element(element_spec)

  defp excluded_namespace?(name, namespace) do
    Map.has_key?(namespace, :excluded_nodes) and is_list(namespace.excluded_nodes) and Enum.member?(namespace.excluded_nodes, name)
  end

  defp add_namespace?(name, namespace),
    do: Map.has_key?(namespace, :tag) and !excluded_namespace?(name, namespace)

  defp indent(level),
    do: String.duplicate("\t", level)

  defp quote_attribute_value(val) when not is_bitstring(val),
    do: quote_attribute_value(to_string(val))

  defp quote_attribute_value(val) do
    double = String.contains?(val, ~s|"|)
    single = String.contains?(val, "'")
    escaped = escape(val)
    cond do
      double && single ->
        escaped |> String.replace("\"", "&quot;") |> quote_attribute_value
      double -> "'#{escaped}'"
      true -> ~s|"#{escaped}"|
    end
  end

  defp escape({:cdata, data}) do
    "<![CDATA[#{data}]]>"
  end

  defp escape(data) when not is_bitstring(data),
    do: escape(to_string(data))

  defp escape(string) do
    string
    |> String.replace(">", "&gt;")
    |> String.replace("<", "&lt;")
    |> replace_ampersand
  end

  defp replace_ampersand(string) do
    Regex.replace(~r/&(?!lt;|gt;|quot;)/, string, "&amp;")
  end
end
