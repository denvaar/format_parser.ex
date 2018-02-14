defmodule FormatParser.AudioTest do
  use ExUnit.Case
  
  test "aiff" do
    {:ok, file} = File.read("priv/test.aiff")

    assert FormatParser.parse(file).format == :aiff
    assert FormatParser.parse(file).nature == :audio
    # assert FormatParser.parse(file).sample_rate_hz == 41_000
    # assert FormatParser.parse(file).num_audio_channels == 2
  end
  
  test "wav" do
    {:ok, file} = File.read("priv/test.wav")

    assert FormatParser.parse(file).format == :wav
    assert FormatParser.parse(file).nature == :audio
    assert FormatParser.parse(file).sample_rate_hz == 48_000
    assert FormatParser.parse(file).num_audio_channels == 2
  end
  
  test "ogg" do
    {:ok, file} = File.read("priv/test.ogg")

    assert FormatParser.parse(file).format == :ogg
    assert FormatParser.parse(file).nature == :audio
    # assert FormatParser.parse(file).sample_rate_hz == 48_000
    # assert FormatParser.parse(file).num_audio_channels == 2
  end
end