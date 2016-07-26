defmodule XmlBuilderPlus do
  @moduledoc """
  A module for generating XML

  ## Examples

      iex> XmlBuilderPlus.doc(:person)
      "<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\" ?>\\n<person/>"

      iex> XmlBuilderPlus.doc(:person, "Josh")
      "<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\" ?>\\n<person>Josh</person>"

      iex> XmlBuilderPlus.element(:person, "Josh") |> XmlBuilderPlus.generate
      "<person>Josh</person>"

      iex> XmlBuilderPlus.element(:person, %{occupation: "Developer"}, "Josh") |> XmlBuilderPlus.generate
      "<person occupation=\\\"Developer\\\">Josh</person>"

      iex> XmlBuilderPlus.namespace([person: "Josh"], "s")
      "<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\" ?>\\n<s:person>Josh</s:person>"
  """

  def add_soap(xml, config, method) do
    if !is_nil(config[:soap]) do
      {:"#{config[:soap][:request_namespace]}:Envelope", get_attributes(method, config, :envelope),[{:"#{config[:soap][:request_namespace]}:Body", get_attributes(method, config, :body), fix_structure(xml)}]}
    else
      xml
    end
  end
  def doc(name_or_tuple),
    do: [:_doc_type | tree_node(name_or_tuple) |> List.wrap] |> generate

  def doc(name, attrs_or_content),
    do: [:_doc_type | [element(name, attrs_or_content)]] |> generate

  def doc(name, attrs, content),
    do: [:_doc_type | [element(name, attrs, content)]] |> generate

  def namespace(name_or_tuple, namespace) when is_list(namespace),
    do: [:_doc_type | tree_node(name_or_tuple) |> List.wrap] |> generate(namespace)
  def namespace(name, attrs_or_content, namespace) when (is_map(attrs_or_content) or is_list(attrs_or_content)) and is_list(namespace),
    do: [:_doc_type | [element(name, attrs_or_content)]] |> generate(namespace)
  def namespace(name, attrs, content, namespace) when is_list(content) and is_list(namespace),
   do: [:_doc_type | [element(name, attrs, content)]] |> generate(namespace)

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

  def element({name, attrs, content}) when is_list(content),
    do: {name, attrs, Enum.map(content, &tree_node/1)}

  def element({name, attrs, content}),
    do: {name, attrs, content}

  def element(name, attrs) when is_map(attrs),
    do: element({name, attrs, nil})

  def element(name, content),
    do: element({name, nil, content})

  def element(name, attrs, content),
    do: element({name, attrs, content})

  def generate(any),
    do: generate(any, 0)

  def generate(any, namespace) when is_list(namespace),
    do: generate(any, 0, namespace)

  def generate(:_doc_type, 0),
    do: ~s|<?xml version="1.0" encoding="UTF-8" ?>|

  def generate(:_doc_type, 0, namespace) when is_list(namespace),
    do: ~s|<?xml version="1.0" encoding="UTF-8" ?>|

  def generate(list, level, namespace) when is_list(list) and is_list(namespace),
    do: list |> Enum.map(&(generate(&1, level, namespace))) |> Enum.intersperse("\n") |> Enum.join

  def generate({name, attrs, content}, level, namespace) when (attrs == nil or map_size(attrs) == 0) and (content==nil or (is_list(content) and length(content)==0)) and is_list(namespace) do
    if !Enum.member?(namespace[:exclude], name) do
      "#{indent(level)}<#{namespace[:namespace]}:#{name}/>"
    else
      "#{indent(level)}<#{name}/>"
    end
  end
  def generate({name, attrs, content}, level, namespace) when content==nil or (is_list(content) and length(content)==0) and is_list(namespace) do
    if !Enum.member?(namespace[:exclude], name) do
      "#{indent(level)}<#{namespace[:namespace]}:#{name} #{generate_attributes(attrs)}/>"
    else
      "#{indent(level)}<#{name} #{generate_attributes(attrs)}/>"
    end
  end
  def generate({name, attrs, content}, level, namespace) when (attrs == nil or map_size(attrs) == 0) and not is_list(content) and is_list(namespace) do
    if !Enum.member?(namespace[:exclude], name) do
      "#{indent(level)}<#{namespace[:namespace]}:#{name}>#{generate_content(content, level+1, namespace)}</#{namespace[:namespace]}:#{name}>"
    else
      "#{indent(level)}<#{name}>#{generate_content(content, level+1, namespace)}</#{name}>"
    end
  end
  def generate({name, attrs, content}, level, namespace) when (attrs == nil or map_size(attrs) == 0) and is_list(content) and is_list(namespace) do
    if !Enum.member?(namespace[:exclude], name) do
      "#{indent(level)}<#{namespace[:namespace]}:#{name}>#{generate_content(content, level+1, namespace)}\n#{indent(level)}</#{namespace[:namespace]}:#{name}>"
    else
      "#{indent(level)}<#{name}>#{generate_content(content, level+1, namespace)}\n#{indent(level)}</#{name}>"
    end
  end
  def generate({name, attrs, content}, level, namespace) when map_size(attrs) > 0 and not is_list(content) and is_list(namespace) do
    if !Enum.member?(namespace[:exclude], name) do
      "#{indent(level)}<#{namespace[:namespace]}:#{name} #{generate_attributes(attrs)}>#{generate_content(content, level+1, namespace)}</#{namespace[:namespace]}:#{name}>"
    else
      "#{indent(level)}<#{name} #{generate_attributes(attrs)}>#{generate_content(content, level+1, namespace)}</#{name}>"
    end
  end
  def generate({name, attrs, content}, level, namespace) when map_size(attrs) > 0 and is_list(content) and is_list(namespace) do
    if !Enum.member?(namespace[:exclude], name) do
      "#{indent(level)}<#{namespace[:namespace]}:#{name} #{generate_attributes(attrs)}>#{generate_content(content, level+1, namespace)}\n#{indent(level)}</#{namespace[:namespace]}:#{name}>"
    else
      "#{indent(level)}<#{name} #{generate_attributes(attrs)}>#{generate_content(content, level+1, namespace)}\n#{indent(level)}</#{name}>"
    end
  end
  def generate(list, level) when is_list(list),
    do: list |> Enum.map(&(generate(&1, level))) |> Enum.intersperse("\n") |> Enum.join
  def generate({name, attrs, content}, level) when (attrs == nil or map_size(attrs) == 0) and (content==nil or (is_list(content) and length(content)==0)),
    do: "#{indent(level)}<#{name}/>"

  def generate({name, attrs, content}, level) when content==nil or (is_list(content) and length(content)==0),
    do: "#{indent(level)}<#{name} #{generate_attributes(attrs)}/>"

  def generate({name, attrs, content}, level) when (attrs == nil or map_size(attrs) == 0) and not is_list(content),
    do: "#{indent(level)}<#{name}>#{generate_content(content, level+1)}</#{name}>"

  def generate({name, attrs, content}, level) when (attrs == nil or map_size(attrs) == 0) and is_list(content),
    do: "#{indent(level)}<#{name}>#{generate_content(content, level+1)}\n#{indent(level)}</#{name}>"

  def generate({name, attrs, content}, level) when map_size(attrs) > 0 and not is_list(content),
    do: "#{indent(level)}<#{name} #{generate_attributes(attrs)}>#{generate_content(content, level+1)}</#{name}>"

  def generate({name, attrs, content}, level) when map_size(attrs) > 0 and is_list(content),
    do: "#{indent(level)}<#{name} #{generate_attributes(attrs)}>#{generate_content(content, level+1)}\n#{indent(level)}</#{name}>"

  defp get_attributes(method, config, type) do
    if !is_nil(config[:soap][:attributes][method][type]) do
      envelope = %{String.replace(config[:soap][:xmlns][type], "{{namespace}}", config[:soap][:soap_namespace]) => config[:soap][:attributes][method][type]}
      for {key, val} <- envelope, into: %{}, do: {String.to_atom(key), val}
    else
      %{}
    end
  end
  defp fix_structure({type, attrs, _document}), do: [{type, attrs, _document}]
  defp tree_node(element_spec),
    do: element(element_spec)

  defp generate_content(children, level) when is_list(children),
    do: "\n" <> Enum.map_join(children, "\n", &(generate(&1, level)))

  defp generate_content(children, level, namespace) when is_list(children) and is_list(namespace),
    do: "\n" <> Enum.map_join(children, "\n", &(generate(&1, level, namespace)))

  defp generate_content(content, _level),
    do: escape(content)

  defp generate_content(content, _level, namespace) when is_list(namespace),
    do: escape(content)

  defp generate_attributes(attrs),
    do: Enum.map_join(attrs, " ", fn {k,v} -> "#{k}=#{quote_attribute_value(v)}" end)

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
