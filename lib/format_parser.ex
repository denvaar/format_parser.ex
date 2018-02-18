defmodule FormatParser do
  @moduledoc """
  The Format Parser
  """

  alias FormatParser.Image
  alias FormatParser.Video
  alias FormatParser.Document
  alias FormatParser.Audio
  alias FormatParser.Font

  @doc """
  Parses the format of a given file. Or returs an error if unknown.

  ## Examples

      iex> {:ok, file} = File.read("priv/test.jpg")
      iex> FormatParser.parse(file)
      %FormatParser.Image{format: :jpg, height_px: nil, nature: :image, width_px: nil}

  """
  @spec parse(binary) :: struct
  def parse(file) do
    case file do
      <<0x89, "PNG", 0x0D, 0x0A, 0x1A, 0x0A, x :: binary>> -> parse_png(x)
      <<"BM", x :: binary>> -> parse_bmp(x)
      <<"GIF89a", x :: binary>> -> parse_gif(x)
      <<"RIFF", x :: binary>> -> parse_wav(x)
      <<"OggS", x :: binary>> -> parse_ogg(x)
      <<"FORM", 0x00, x :: binary>> -> parse_aiff(x)
      <<"fLaC", x :: binary>> -> parse_flac(x)
      <<"FLV", 0x01, x :: binary>> -> parse_flv(x)
      <<"GIF87a", x :: binary>> -> parse_gif(x)
      <<0xFF, 0xD8, 0xFF, x :: binary>> -> parse_jpeg(x)
      <<0x49, 0x49, 0x2A, 0x00, 0x10, 0x00, 0x00, 0x00, 0x43, 0x52, x :: binary>> -> parse_cr2(x)
      <<0x49, 0x49, 0x2A, 0x00, x :: binary>> -> parse_tif(x)
      <<0x00, 0x00, 0x01, 0x00, x :: binary>> -> parse_ico(x)
      <<0x7B, 0x5C, 0x72, 0x74, 0x66, 0x31, x :: binary>> -> parse_rtf(x)
      <<0x00, 0x01, 0x00, 0x00, 0x00, x :: binary>> -> parse_ttf(x)
      <<"true", 0x00, x :: binary>> -> parse_ttf(x)
      <<"OTTO", 0x00, x :: binary>> -> parse_otf(x)
      <<"ID3", x :: binary>> -> parse_mp3(x)
      <<"8BPS", x :: binary>> -> parse_psd(x)
      <<0x4d, 0x5A, x :: binary>> -> parse_fon(x)
      _ -> {:error, "Unknown"}
    end
  end

  defp parse_fon(<<_x :: binary>>) do
    %Font{format: :fon}
  end

  defp parse_psd(<<_x :: binary>>) do
    %Image{format: :psd}
  end

  defp parse_mp3(<<_x :: binary>>) do
    %Audio{format: :mp3}
  end

  defp parse_otf(<<_x :: binary>>) do
    %Font{format: :otf}
  end

  defp parse_ttf(<<_x :: binary>>) do
    %Font{format: :ttf}
  end

  defp parse_rtf(<<_x :: binary>>) do
    %Document{format: :rtf}
  end

  defp parse_ico(<<_x:: binary>>) do
    %Image{format: :ico}
  end

  defp parse_tif(<< ifd_offset  :: little-integer-size(32), _x :: binary >>) do
    offset = (ifd_offset - 8) * 8
    ifd_set = parse_ifd(<< _x :: binary >>, offset)

    width = Enum.find(ifd_set, fn(x) -> x[:tag] == 256 end)
    height = Enum.find(ifd_set, fn(x) -> x[:tag] == 257 end)
    make = Enum.find(ifd_set, fn(x) -> x[:tag] == 271 end)

    if make && Regex.match?(~r/nikon .+/, make[:value]) do
      %Image{format: :nef, width_px: width[:value], height_px: height[:value]}
    else
      %Image{format: :tif, width_px: width[:value], height_px: height[:value]}
    end
  end

  defp parse_ifd(<< _x :: binary >>, offset) do
    <<
      _head :: size(offset), size :: little-integer-size(16),
      ifd_1st :: size(96), ifd_2nd :: size(96), ifd_3rd :: size(96),
      _chunk :: size(288), ifd_make :: size(96),  _rest :: binary
    >> = << _x :: binary >>

    Enum.map([ifd_1st, ifd_2nd, ifd_3rd, ifd_make], fn(x) ->
      ifd = ifd_tag(<< _x :: binary >>, << x :: size(96) >>)
      %{tag: ifd[:tag], value: ifd[:value], length: ifd[:length]}
    end)
  end

  defp ifd_tag(<< _x ::binary >>, << tag :: little-integer-size(16), type :: little-integer-size(16), length :: little-integer-size(32), value :: little-integer-size(32) >>) do
    case type do
      2 -> val = parse_string(<< _x ::binary >>, (value - 8) * 8, length  * 8) |> String.downcase
      _ -> val = value
    end
    %{tag: tag, value: val, length: length}
  end

  defp parse_string(<< _x ::binary >>, offset, length) do
    << _ :: size(offset), string :: size(length), _ :: binary >> = << _x :: binary >>
    << string :: size(length)  >>
  end

  defp parse_cr2(<<_x:: binary>>) do
    %Image{format: :cr2}
  end

  defp parse_flac(<<_x:: binary>>) do
    %Audio{format: :flac}
  end

  defp parse_ogg(<<_x:: binary>>) do
    %Audio{format: :ogg}
  end

  defp parse_wav(<<_ :: size(144), channels :: little-integer-size(16), sample_rate_hz :: little-integer-size(32), _x :: binary>>) do
    %Audio{format: :wav, sample_rate_hz: sample_rate_hz, num_audio_channels: channels}
  end

  defp parse_aiff(<<_ :: size(56), "COMM", _ :: size(96), sample_rate_hz :: size(80), _x :: binary>>) do
    %Audio{format: :aiff, sample_rate_hz: sample_rate_hz}
  end

  defp parse_flv(_x) do
    %Video{format: :flv}
  end

  defp parse_gif(<< width :: little-integer-size(16), height :: little-integer-size(16), _x :: binary>>) do
    %Image{format: :gif, width_px: width, height_px: height}
  end

  defp parse_jpeg(_binary) do
    %Image{format: :jpg}
  end

  defp parse_bmp(<< _header :: size(128), width :: little-integer-size(32), height :: little-integer-size(32), _x :: binary>>) do
    %Image{format: :bmp, width_px: width, height_px: height}
  end

  defp parse_png(<< _length :: size(32), "IHDR", width :: size(32), height :: size(32), _x :: binary>>) do
    %Image{format: :png, width_px: width, height_px: height}
  end
end
