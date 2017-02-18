defmodule Readability.HelperTest do
  use ExUnit.Case, async: true

  import Readability, only: [parse: 1]
  alias Readability.Helper

  @sample """
    <html>
      <body>
        <p>
          <font>a</fond>
          <p>
            <font>abc</font>
          </p>
        </p>
        <p>
          <font>b</font>
        </p>
      </body>
    </html>
  """


  @relative """
    <html>
      <body>
        <a href="test.html">Test</a>
        <a href="../test.html">Test</a>
        <a href="./foo/bar/test.html#id">Test</a>

        <img src="/wp-content/assets/dist/img/px.gif" />
        <img src="./foo/test.gif" />
      </body>
    </html>
  """

  setup do
    html_tree = Floki.parse(@sample)
    links_tree = Floki.parse(@relative)
    {:ok, html_tree: html_tree, links_tree: links_tree}
  end

  test "change font tag to span", %{html_tree: html_tree} do
    expectred = @sample |> String.replace(~r/font/, "span") |> Floki.parse
    result = Helper.change_tag(html_tree, "font", "span")
    assert result == expectred
  end

  test "remove tag", %{html_tree: html_tree} do
    expected = "<html><body></body></html>" |> parse
    result = html_tree
             |> Helper.remove_tag(fn({tag, _, _}) ->
               tag == "p"
             end)

    assert result == expected
  end

  test "inner text lengt", %{html_tree: html_tree} do
    result = html_tree |> Helper.text_length
    assert result == 5
  end

  test "convert relative paths to absolute", %{links_tree: links_tree} do
    result = links_tree |> Helper.to_absolute("https://base.com/dir/")
      
    transformed_links = result |> Floki.find("a") |> Floki.attribute("href")
    assert transformed_links == ["https://base.com/dir/test.html", "https://base.com/test.html", "https://base.com/dir/foo/bar/test.html#id"]

    transformed_images = result |> Floki.find("img") |> Floki.attribute("src")
    assert transformed_images == ["https://base.com/wp-content/assets/dist/img/px.gif", "https://base.com/dir/foo/test.gif"]
  end
end
