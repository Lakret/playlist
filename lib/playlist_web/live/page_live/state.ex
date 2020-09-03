defmodule PlaylistWeb.PageLive.State do
  @moduledoc """
  Logic for working with the state of the play queue.
  """
  alias PlaylistWeb.PageLive.Track

  defstruct ~w(playing_idx play_position_secs paused_idx queue)a

  @type t :: %__MODULE__{
          playing_idx: non_neg_integer() | nil,
          play_position_secs: non_neg_integer() | nil,
          paused_idx: non_neg_integer() | nil,
          queue: [Track.t()]
        }

  @doc """
  Advances play position in the current playing track
  by `seconds` (defaults to 1 second).

  If the length of the current track is exceeded,
  starts the playback of the next track in `state`'s queue.

  Does nothing if nothing is playing.
  """
  @spec advance_play_position(t(), non_neg_integer()) :: t()
  def advance_play_position(state, seconds \\ 1) do
    case get_playing_track(state) do
      nil ->
        state

      %Track{length: length} ->
        new_play_position_secs = state.play_position_secs + seconds

        play_position_time =
          new_play_position_secs
          |> :calendar.seconds_to_time()
          |> Time.from_erl!()

        if Time.compare(play_position_time, length) == :gt do
          play_next(state)
        else
          %{state | play_position_secs: new_play_position_secs}
        end
    end
  end

  @doc """
  Returns the current play position as `Time`;
  if nothing is playing, returns `nil`.
  """
  @spec get_play_position(t()) :: Time.t() | nil
  def get_play_position(state)

  def get_play_position(%__MODULE__{play_position_secs: nil}), do: nil

  def get_play_position(%__MODULE__{play_position_secs: position}) do
    position
    |> :calendar.seconds_to_time()
    |> Time.from_erl!()
  end

  @doc """
  Returns the current play position as percentage of
  the total length of the playing track.

  If nothing is playing, or track has no length,
  or there's no play position, returns 0.
  """
  @spec get_play_position_percentage(t()) :: number()
  def get_play_position_percentage(%__MODULE__{} = state) do
    case get_playing_track(state) do
      nil ->
        0

      %Track{length: length} ->
        length_seconds = length |> Time.to_erl() |> :calendar.time_to_seconds()

        if length_seconds != 0 && !is_nil(state.play_position_secs) do
          state.play_position_secs / length_seconds * 100
        else
          0
        end
    end
  end

  @doc """
  Get the length of the currently playing track,
  or, if not playing, the length of the paused track.

  If there is no paused track, returns 0 seconds.
  """
  @spec get_playing_or_paused_track_length(t()) :: Time.t()
  def get_playing_or_paused_track_length(%__MODULE__{} = state) do
    case get_playing_track(state) do
      nil ->
        case get_paused_track(state) do
          nil -> ~T[00:00:00]
          %Track{length: length} -> length
        end

      %Track{length: length} ->
        length
    end
  end

  @doc """
  Sets play position of the current playing track
  to the specified `track_position_percentage` (should be between 0 and 1).

  If the length of the current track is exceeded,
  starts the playback of the next track in `state`'s queue.

  Does nothing if nothing is playing.
  """
  @spec set_play_position(t(), float()) :: t()
  def set_play_position(%__MODULE__{} = state, track_position_percentage) do
    case get_playing_track(state) do
      nil ->
        state

      %Track{length: length} ->
        length_seconds = length |> Time.to_erl() |> :calendar.time_to_seconds()

        new_play_position_secs = round(length_seconds * track_position_percentage)

        play_position_time =
          new_play_position_secs
          |> :calendar.seconds_to_time()
          |> Time.from_erl!()

        if Time.compare(play_position_time, length) == :gt do
          play_next(state)
        else
          %{state | play_position_secs: new_play_position_secs}
        end
    end
  end

  @doc """
  Checks if the `state` is in playback mode.
  """
  @spec playing?(t()) :: boolean()
  def playing?(state), do: !is_nil(state.playing_idx)

  @doc """
  Returns the currently playing track, or `nil`.
  """
  @spec get_playing_track(t()) :: Track | nil
  def get_playing_track(state)

  def get_playing_track(%__MODULE__{playing_idx: nil}), do: nil

  def get_playing_track(%__MODULE__{playing_idx: idx} = state)
      when is_integer(idx) do
    Enum.at(state.queue, idx)
  end

  @doc """
  Returns the index of the currently playing track in the queue,
  or `nil` if nothing is playing.
  """
  @spec get_playing_track_idx(t()) :: non_neg_integer() | nil
  def get_playing_track_idx(%__MODULE__{playing_idx: idx}), do: idx

  @doc """
  Returns the paused track, or `nil`.
  """
  @spec get_playing_track(t()) :: Track | nil
  def get_paused_track(state)

  def get_paused_track(%__MODULE__{paused_idx: nil}), do: nil

  def get_paused_track(%__MODULE__{paused_idx: idx} = state)
      when is_integer(idx) do
    Enum.at(state.queue, idx)
  end

  @doc """
  Toggles playback if it was paused, or pauses playback
  if it was in the playing mode.
  """
  @spec toggle_play_or_pause(t()) :: t()
  def toggle_play_or_pause(state) do
    if playing?(state) do
      pause(state)
    else
      play(state)
    end
  end

  @doc """
  Pause the playback in the `state`.
  """
  @spec pause(t()) :: t()
  def pause(state)

  def pause(%__MODULE__{playing_idx: nil} = state), do: state

  def pause(%__MODULE__{playing_idx: idx} = state) do
    %{state | playing_idx: nil, paused_idx: idx}
  end

  @doc """
  Starts playback in the `state`.

  Takes into account situations where something is
  already played (nothing will happen then),
  or when something was paused before (the playback will start
  with that track).
  """
  @spec play(t()) :: t()
  def play(state)

  def play(%__MODULE__{playing_idx: idx} = state) when is_integer(idx), do: state

  def play(%__MODULE__{playing_idx: nil, paused_idx: nil} = state) do
    %{state | playing_idx: 0, play_position_secs: 0}
  end

  def play(%__MODULE__{playing_idx: nil, paused_idx: idx} = state) when is_integer(idx) do
    %{state | playing_idx: idx, play_position_secs: 0, paused_idx: nil}
  end

  @doc """
  Play a track by its `index` in the queue in `state`.
  """
  @spec play_by_index(t(), non_neg_integer()) :: t()
  def play_by_index(%__MODULE__{} = state, index) when is_integer(index) and index >= 0 do
    %{state | playing_idx: index, play_position_secs: 0}
  end

  @doc """
  Plays the next track in queue in `state`.
  If nothing is playing, starts the playback.

  Returns the new state.
  """
  @spec play_next(t()) :: t()
  def play_next(%__MODULE__{} = state) do
    if playing?(state) do
      max_idx = length(state.queue) - 1
      playing_idx = min(state.playing_idx + 1, max_idx)

      %{state | playing_idx: playing_idx, play_position_secs: 0}
    else
      play(state)
    end
  end

  @doc """
  Plays the previous track in queue in `state`.

  If nothing is playing, starts the playback.
  """
  @spec play_previous(t()) :: t()
  def play_previous(%__MODULE__{} = state) do
    if playing?(state) do
      playing_idx = max(state.playing_idx - 1, 0)
      %{state | playing_idx: playing_idx, play_position_secs: 0}
    else
      play(state)
    end
  end
end
