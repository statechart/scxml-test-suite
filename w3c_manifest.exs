defmodule Fetch do
  import Record

  extract_all(from_lib: "xmerl/include/xmerl.hrl")
  |> Enum.each(fn({name, kvs}) ->
    defrecord(name, kvs)
  end)

  def run(manifest, touchfile, host) do
    dir = Path.dirname(touchfile)
    {doc, _misc} = :xmerl_scan.file(manifest)

    doc
    |> children()
    |> Enum.flat_map(fn
      (xmlElement(name: :assert) = assert) ->
        spec = get_attr(assert, :specnum) |> to_string() |> String.replace("#", "")
        [description, test] = children(assert)
        description = to_string(xmlText(description, :value))
        if get_attr(test, :manual) == 'false' do
          conformance = get_attr(test, :conformance) |> to_string()
          test
          |> children()
          |> Stream.map(&get_attr(&1, :uri))
          |> Stream.filter((&Path.extname(&1) == ".txml"))
          |> Enum.map(fn(uri) ->
            id = Path.basename(uri, ".txml")
            {"#{host}/#{uri}", id, conformance, spec, description}
          end)
        else
          []
        end
      (xmlText()) ->
        []
    end)
    |> Enum.map(fn({uri, id, conformance, spec, description}) ->
      name = "#{dir}/#{conformance}/#{spec}/#{id}"
      template = "#{name}.txml"
      if !File.exists?(template) do
        Etude.Request.get(uri)
        |> Etude.map(fn(%{body: body}) ->
          name |> Path.dirname() |> File.mkdir_p!()
          File.write!(template, body)
          File.write!("#{name}.description", description)
          true
        end)
      end
    end)
    |> Etude.join(10)
    |> Etude.fork!()

    File.touch!(touchfile)
  end

  defp get_attr(xmlElement(attributes: attrs), name) do
    Enum.find_value(attrs, fn
      (xmlAttribute(name: ^name, value: value)) ->
        value
      (_) ->
        false
    end)
  end

  defp children(xmlElement(content: content)) do
    content
    |> Enum.filter(fn
      (xmlElement()) -> true
      (xmlText(type: :cdata)) -> true
      (_) -> false
    end)
  end
end

Application.ensure_all_started(:etude_request)
[manifest, touchfile, host] = System.argv
Fetch.run(manifest, touchfile, host)
