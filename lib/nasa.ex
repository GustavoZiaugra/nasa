defmodule Nasa do
  alias Ets.Set.KeyValueSet

  @moduledoc """
    Module responsible for carrying out the movements of a sonar.
  """

  @coordination %{
    "L" => %{"S" => "E", "E" => "N", "N" => "W", "W" => "S"},
    "R" => %{"E" => "S", "N" => "E", "W" => "N", "S" => "W"}
  }

  @doc """
  Main method responsible to receive a path of a text file and
  then return the final position of all sonar presents.
  """
  def run(path) do
    case File.exists?(path) do
      true ->
        content =
          File.read!(path)
          |> String.split("\n")
          |> Stream.with_index(0)
          |> Enum.filter(&("" != &1))
          |> Enum.filter(&(!is_nil(&1)))
          |> Enum.reduce(%{}, fn {v, k}, acc -> Map.put(acc, k, v) end)

        {:ok, set} = KeyValueSet.new()

        highland = parse(:highland, content[0])

        Enum.each(content, fn {k, v} ->
          unless k == 0 || v == "" || rem(k, 2) == 0 do
            do_action(set, k, parse(:sonar, v), parse(:moves, content[k + 1]), highland)
          end
        end)

        show_result(set)

      false ->
        raise ArgumentError, "Your file may not exist!"
    end
  end

  # need to figure out how to silence :ok at end of method
  @doc """
  Returns all sonar final positions following this format:
  (x, y, coordination)
  """
  def show_result(set) do
    {:ok, list} =
      set
      |> KeyValueSet.to_list()

    list
    |> Enum.each(fn {_k, v} ->
      sonar = Map.get(v, :sonar)

      Enum.join([sonar[:x], sonar[:y], sonar[:coordination]], " ")
      |> IO.puts()
    end)
  end

  @doc """
  Set a sonar to ETS and also apply all related moves
  """
  def do_action(set, index, sonar, moves, highland) do
    set(set, index, sonar, moves, highland)
    apply_moves(set, index)
  end

  @doc """
  Store a map into ETS.
  """
  def set(set, index, sonar, moves, highland) do
    KeyValueSet.put(set, index, %{sonar: sonar, moves: moves, highland: highland})
  end

  @doc """
  Update a Map into ETS.
  """
  def update_set(set, index, map) do
    KeyValueSet.put(set, index, map)
  end

  @doc """
  Return a struct from ETS.
  """
  def fetch_struct(set, index) do
    KeyValueSet.get!(set, index)
  end

  @doc """
    Parses all structs following the needs of each case.
  """
  def parse(:moves, data) do
    data
    |> String.split("")
    |> Enum.filter(&("" != &1))
  end

  def parse(:highland, data) do
    highland =
      data
      |> String.split(" ")
      |> Enum.filter(&("" != &1))

    {x, _} = Enum.at(highland, 0) |> Integer.parse()
    {y, _} = Enum.at(highland, 1) |> Integer.parse()
    %{x: x, y: y}
  end

  def parse(:sonar, data) do
    sonar =
      data
      |> String.split(" ")
      |> Enum.filter(&(!is_nil(&1)))
      |> Enum.filter(&("" != &1))

    {x, _} = Enum.at(sonar, 0) |> Integer.parse()
    {y, _} = Enum.at(sonar, 1) |> Integer.parse()

    %{
      x: x,
      y: y,
      coordination: Enum.at(sonar, 2)
    }
  end

  @doc """
  Change a coordenate from a sonar according with received move.
  """
  def change_coordenate(set, index, coordenate) do
    struct = fetch_struct(set, index)

    sonar =
      struct
      |> Map.get(:sonar)

    new_sonar = Map.put(sonar, :coordination, @coordination[coordenate][sonar[:coordination]])
    new_struct = Map.put(struct, :sonar, new_sonar)

    update_set(set, index, new_struct)
  end

  @doc """
  Change a position from a sonar into axis x or y according with received move.
  """
  def change_position(set, index) do
    sonar = fetch_struct(set, index) |> Map.get(:sonar)

    case sonar[:coordination] do
      "N" ->
        increase_position(set, :y, index)

      "S" ->
        decrease_position(set, :y, index)

      "W" ->
        decrease_position(set, :x, index)

      "E" ->
        increase_position(set, :x, index)
    end

    sonar
  end

  @doc """
  Responsible to redirect to the correct method to change coordenate or position
  from a sonar.
  """
  def apply_moves(set, index) do
    moves = fetch_struct(set, index) |> Map.get(:moves)

    Enum.each(moves, fn move ->
      if move == "L" or move == "R" do
        change_coordenate(set, index, move)
      else
        change_position(set, index)
      end
    end)
  end

  @doc """
  Responsible to increase position into axis x or y from a sonar.
  """
  def increase_position(set, :x, index) do
    struct = fetch_struct(set, index)

    sonar =
      struct
      |> Map.get(:sonar)

    new_sonar = Map.put(sonar, :x, sonar[:x] + 1)
    new_struct = Map.put(sonar, :sonar, new_sonar)
    update_set(set, index, new_struct)
  end

  def increase_position(set, :y, index) do
    struct = fetch_struct(set, index)

    sonar =
      struct
      |> Map.get(:sonar)

    new_sonar = Map.put(sonar, :y, sonar[:y] + 1)
    new_struct = Map.put(struct, :sonar, new_sonar)
    update_set(set, index, new_struct)
  end

  @doc """
  Responsible to decrease position into axis x or y from a sonar.
  """
  def decrease_position(set, :y, index) do
    struct = fetch_struct(set, index)

    sonar =
      struct
      |> Map.get(:sonar)

    new_sonar = Map.put(sonar, :y, sonar[:y] - 1)
    new_struct = Map.put(struct, :sonar, new_sonar)
    update_set(set, index, new_struct)
  end

  def decrease_position(set, :x, index) do
    struct = fetch_struct(set, index)

    sonar =
      struct
      |> Map.get(:sonar)

    new_sonar = Map.put(sonar, :x, sonar[:x] - 1)
    new_struct = Map.put(struct, :sonar, new_sonar)
    update_set(set, index, new_struct)
  end
end
