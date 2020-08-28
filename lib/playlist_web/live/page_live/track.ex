defmodule PlaylistWeb.PageLive.Track do
  defstruct [:title, :artist, :album, :length]

  def new(title, artist, album, length) do
    %__MODULE__{title: title, artist: artist, album: album, length: length}
  end
end
