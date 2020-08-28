defmodule PlaylistWeb.PageView do
  use PlaylistWeb, :view

  def pretty_time(length) do
    {hours, minutes, seconds} = {length.hour, length.minute, length.second}

    seconds = to_string(seconds) |> String.pad_leading(2, "0")

    if hours == 0 do
      "#{minutes}:#{seconds}"
    else
      minutes = to_string(minutes) |> String.pad_leading(2, "0")

      "#{hours}:#{minutes}:#{seconds}"
    end
  end
end
