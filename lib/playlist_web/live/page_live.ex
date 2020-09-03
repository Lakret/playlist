defmodule PlaylistWeb.PageLive do
  use PlaylistWeb, :live_view

  alias PlaylistWeb.PageLive.{State, Track}

  @impl true
  def mount(_params, _session, socket) do
    state = init_state()
    state = %{state | queue: List.duplicate(state.queue, 10) |> List.flatten()}

    if connected?(socket) do
      :timer.send_interval(1000, :tick)
    end

    {:ok, assign(socket, state: state)}
  end

  defp init_state() do
    %State{
      playing_idx: 4,
      play_position_secs: 0,
      paused_idx: nil,
      queue: [
        Track.new("Cern", "Monolake", "Momentum", ~T[00:04:10]),
        Track.new("Linear", "Monolake", "Momentum", ~T[00:02:15]),
        Track.new("Atomium", "Monolake", "Momentum", ~T[00:03:07]),
        Track.new("White_li", "Monolake", "Momentum", ~T[00:06:28]),
        Track.new("Tetris", "Monolake", "Momentum", ~T[00:05:17]),
        Track.new("Blow Your Trumpets Gabriel", "Behemoth", "The Satanist", ~T[00:08:25]),
        Track.new("Furor Divinus", "Behemoth", "The Satanist", ~T[00:14:05]),
        Track.new("Messe Noir", "Behemoth", "The Satanist", ~T[00:02:00]),
        Track.new("Ora Pro Nobis Lucifer", "Behemoth", "The Satanist", ~T[00:00:15]),
        Track.new("The Satanist", "Behemoth", "The Satanist", ~T[02:01:00])
      ]
    }
  end

  @impl true
  def handle_info(:tick, socket) do
    state = State.advance_play_position(socket.assigns.state)
    {:noreply, assign(socket, state: state)}
  end

  @impl true
  def handle_event("play_this", %{"track-idx" => track_idx}, socket) do
    {track_idx, ""} = Integer.parse(track_idx)
    state = State.play_by_index(socket.assigns.state, track_idx)

    socket = assign(socket, :state, state)
    {:noreply, socket}
  end

  def handle_event("play_or_pause", _params, socket) do
    state = State.toggle_play_or_pause(socket.assigns.state)
    {:noreply, assign(socket, state: state)}
  end

  def handle_event("previous", _params, socket) do
    state = State.play_previous(socket.assigns.state)
    {:noreply, assign(socket, state: state)}
  end

  def handle_event("next", _params, socket) do
    state = State.play_next(socket.assigns.state)
    {:noreply, assign(socket, state: state)}
  end

  def handle_event("scrub", params, socket) do
    position_control_length = params["elementMaxX"] - params["elementMinX"]
    normalized_click_position = params["clientX"] - params["elementMinX"]
    track_position_percentage = normalized_click_position / position_control_length

    state = State.set_play_position(socket.assigns.state, track_position_percentage)
    {:noreply, assign(socket, state: state)}
  end
end
