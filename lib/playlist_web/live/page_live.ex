defmodule PlaylistWeb.PageLive do
  use PlaylistWeb, :live_view

  alias PlaylistWeb.PageLive.{State, Track}

  @impl true
  def mount(_params, _session, socket) do
    state = init_state()
    state = %{state | queue: List.duplicate(state.queue, 10) |> List.flatten(), grouping: :album}

    if connected?(socket) do
      :timer.send_interval(1000, :tick)
    end

    socket =
      assign(socket,
        state: state,
        # We use `tick_count` to prevent us from looping between
        # scrolling to the new playing track when somebody presses on
        # the play button on the track, or next track / prev track buttons,
        # and us detecting user scrolling.
        # We distinguish between user scrolling & our scrolling by comparing tick counts
        # in `play_selected_last_tick` (the tick count observed during
        # the last `play_this`, `previous`, or `next` event handler execution)
        # and the current `tick_count`.
        scroll_to_playing_track: true,
        tick_count: 0,
        play_selected_last_tick: 0
      )

    {:ok, socket}
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

  ## Server-generated events

  @impl true
  def handle_info(:tick, socket) do
    state = State.advance_play_position(socket.assigns.state)

    socket =
      assign(socket, state: state, tick_count: socket.assigns.tick_count + 1)
      |> push_playing_track_scroll_event_if_needed()

    {:noreply, socket}
  end

  ## Client events

  # Scroll detection is nedded to avoid jumping user to unexpected
  # position when a new track starts playing when the user explores
  # the playlist. We use `tick_count` and `play_selected_last_tick`
  # to distinguish between user scrolling the playlist (in which
  # case we need to disable auto-scrolling to the new current playing track
  # by setting `scroll_to_playing_track` to `false`), and user clicking
  # on the `play_this`, `previous`, or `next` buttons that leads us
  # to always scrolling to the newly playing track,
  # and setting `scroll_to_playing_track` to `true` to re-enable auto-scrolling.
  @impl true
  def handle_event("playlist_scroll_detected", _params, socket) do
    # user scrolling
    socket =
      if socket.assigns.tick_count - socket.assigns.play_selected_last_tick >= 1 do
        assign(socket, scroll_to_playing_track: false)
        # auto-scrolling on new track
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("play_this", %{"track-idx" => track_idx}, socket) do
    {track_idx, ""} = Integer.parse(track_idx)
    state = State.play_by_index(socket.assigns.state, track_idx)

    socket =
      assign(socket,
        state: state,
        # those are helpers for intelligent scrolling behavior
        # we need to record the current `tick_count` here
        # to distinguish between the scroll event we generate,
        # and user generated scroll event.
        scroll_to_playing_track: true,
        play_selected_last_tick: socket.assigns.tick_count
      )
      |> push_playing_track_scroll_event_if_needed()

    {:noreply, socket}
  end

  def handle_event("play_or_pause", _params, socket) do
    state = State.toggle_play_or_pause(socket.assigns.state)
    {:noreply, assign(socket, state: state)}
  end

  def handle_event("previous", _params, socket) do
    state = State.play_previous(socket.assigns.state)

    socket =
      assign(socket,
        state: state,
        # see comment in `play_this` handler
        scroll_to_playing_track: true,
        play_selected_last_tick: socket.assigns.tick_count
      )
      |> push_playing_track_scroll_event_if_needed()

    {:noreply, socket}
  end

  def handle_event("next", _params, socket) do
    state = State.play_next(socket.assigns.state)

    socket =
      assign(socket,
        state: state,
        # see comment in `play_this` handler
        scroll_to_playing_track: true,
        play_selected_last_tick: socket.assigns.tick_count
      )
      |> push_playing_track_scroll_event_if_needed()

    {:noreply, socket}
  end

  def handle_event("scrub", params, socket) do
    position_control_length = params["elementMaxX"] - params["elementMinX"]
    normalized_click_position = params["clientX"] - params["elementMinX"]
    track_position_percentage = normalized_click_position / position_control_length

    state = State.set_play_position(socket.assigns.state, track_position_percentage)
    {:noreply, assign(socket, state: state)}
  end

  def handle_event("change_grouping", %{"grouping" => grouping}, socket) do
    grouping = String.to_existing_atom(grouping)

    if grouping != socket.assigns.state.grouping do
      socket =
        assign(socket, state: %{socket.assigns.state | grouping: grouping})
        |> push_playing_track_scroll_event()

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  ## Helpers

  # Pushes `scroll_to_playing_track` event to client JS if user
  # didn't scroll the playlist manually after pressing play for a specific track
  # (see `play_this` handler), or `previous` / `next` buttons.
  @spec push_playing_track_scroll_event_if_needed(Socket.t()) :: Socket.t()
  defp push_playing_track_scroll_event_if_needed(socket) do
    if socket.assigns.scroll_to_playing_track do
      push_playing_track_scroll_event(socket)
    else
      socket
    end
  end

  # Unconditionally pushes `scroll_to_playing_track` event to client JS.
  @spec push_playing_track_scroll_event_if_needed(Socket.t()) :: Socket.t()
  def push_playing_track_scroll_event(socket) do
    playing_track_idx = State.get_playing_track_idx(socket.assigns.state)

    push_event(socket, "scroll_to_playing_track", %{track_idx: playing_track_idx})
  end
end
