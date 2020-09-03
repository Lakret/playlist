defmodule PlaylistWeb.PageLive.Track do
  @moduledoc """
  TODO:
  """

  defstruct [:title, :artist, :album, :length]

  @type t :: %__MODULE__{
          title: String.t(),
          artist: String.t(),
          album: String.t(),
          length: Time.t()
        }

  @doc """
  Creates a new track.
  """
  @spec new(String.t(), String.t(), String.t(), Time.t()) :: t()
  def new(title, artist, album, length) do
    %__MODULE__{title: title, artist: artist, album: album, length: length}
  end
end
