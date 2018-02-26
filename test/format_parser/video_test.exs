defmodule FormatParser.VideoTest do
  use ExUnit.Case
  
  test "flv" do
    {:ok, file} = File.read("priv/test.flv")

    assert FormatParser.parse(file).format == :flv
    assert FormatParser.parse(file).nature == :video
  end
end
