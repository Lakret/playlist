defmodule PlaylistWeb.PageLive do
  use PlaylistWeb, :live_view

  alias PlaylistWeb.PageLive.Track

  defmodule Track do
    defstruct [:title, :artist, :album]

    def new(title, artist, album) do
      %__MODULE__{title: title, artist: artist, album: album}
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    state = init_state()
    state = %{state | queue: List.duplicate(state.queue, 10) |> List.flatten()}

    {:ok, assign(socket, state)}
  end

  defp init_state() do
    %{
      playing_idx: 4,
      queue: [
        Track.new("Cern", "Monolake", "Momentum"),
        Track.new("Linear", "Monolake", "Momentum"),
        Track.new("Atomium", "Monolake", "Momentum"),
        Track.new("White_li", "Monolake", "Momentum"),
        Track.new("Tetris", "Monolake", "Momentum"),
        Track.new("Blow Your Trumpets Gabriel", "Behemoth", "The Satanist"),
        Track.new("Furor Divinus", "Behemoth", "The Satanist"),
        Track.new("Messe Noir", "Behemoth", "The Satanist"),
        Track.new("Ora Pro Nobis Lucifer", "Behemoth", "The Satanist"),
        Track.new("The Satanist", "Behemoth", "The Satanist")
      ]
    }
  end

  @impl true
  def handle_event("play_this", %{"track-idx" => track_idx}, socket) do
    {track_idx, ""} = Integer.parse(track_idx)
    socket = assign(socket, :playing_idx, track_idx)

    {:noreply, socket}
  end

  def handle_event("play_or_pause", _params, socket) do
    socket =
      if socket.assigns.playing_idx do
        assign(socket, :playing_idx, nil)
      else
        assign(socket, :playing_idx, 0)
      end

    {:noreply, socket}
  end

  def handle_event("previous", _params, socket) do
    if socket.assigns.playing_idx do
      playing_idx = max(socket.assigns.playing_idx - 1, 0)

      socket = assign(socket, :playing_idx, playing_idx)
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("next", _params, socket) do
    if socket.assigns.playing_idx do
      max_idx = length(socket.assigns.queue) - 1
      playing_idx = min(socket.assigns.playing_idx + 1, max_idx)

      socket = assign(socket, :playing_idx, playing_idx)
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end
end
