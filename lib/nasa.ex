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

        try do
          highland = parse(:highland, content[0])

          Enum.each(content, fn {k, v} ->
            unless k == 0 || v == "" || rem(k, 2) == 0 do
              do_action(set, k, parse(:sonar, v), parse(:moves, content[k + 1]), highland)
            end
          end)

          show_result(set)
        rescue
          _ -> raise ArgumentError, "Your file has invalid data"
        end

      false ->
        raise ArgumentError, "Your file may not exist!"
    end
  end

  defp show_result(set) do
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

  defp do_action(set, index, sonar, moves, highland) do
    set(set, index, sonar, moves, highland)
    apply_moves(set, index)
  end

  defp set(set, index, sonar, moves, highland) do
    KeyValueSet.put(set, index, %{sonar: sonar, moves: moves, highland: highland})
  end

  defp update_set(set, index, map) do
    KeyValueSet.put(set, index, map)
  end

  defp fetch_struct(set, index) do
    KeyValueSet.get!(set, index)
  end

  defp parse(:moves, data) do
    data
    |> String.split("")
    |> Enum.filter(&("" != &1))
  end

  defp parse(:highland, data) do
    highland =
      data
      |> String.split(" ")
      |> Enum.filter(&("" != &1))

    {x, _} = Enum.at(highland, 0) |> Integer.parse()
    {y, _} = Enum.at(highland, 1) |> Integer.parse()
    %{x: x, y: y}
  end

  defp parse(:sonar, data) do
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

  defp change_coordinate(set, index, coordenate) do
    struct = fetch_struct(set, index)

    sonar =
      struct
      |> Map.get(:sonar)

    new_sonar = Map.put(sonar, :coordination, @coordination[coordenate][sonar[:coordination]])
    new_struct = Map.put(struct, :sonar, new_sonar)

    update_set(set, index, new_struct)
  end

  defp change_position(set, index) do
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

  defp apply_moves(set, index) do
    moves = fetch_struct(set, index) |> Map.get(:moves)

    Enum.each(moves, fn move ->
      case move do
        "L" ->
          change_coordinate(set, index, move)

        "R" ->
          change_coordinate(set, index, move)

        "M" ->
          change_position(set, index)
      end
    end)
  end

  defp increase_position(set, :x, index) do
    struct = fetch_struct(set, index)

    sonar =
      struct
      |> Map.get(:sonar)

    new_sonar = Map.put(sonar, :x, sonar[:x] + 1)
    new_struct = Map.put(sonar, :sonar, new_sonar)
    update_set(set, index, new_struct)
  end

  defp increase_position(set, :y, index) do
    struct = fetch_struct(set, index)

    sonar =
      struct
      |> Map.get(:sonar)

    new_sonar = Map.put(sonar, :y, sonar[:y] + 1)
    new_struct = Map.put(struct, :sonar, new_sonar)
    update_set(set, index, new_struct)
  end

  defp decrease_position(set, :y, index) do
    struct = fetch_struct(set, index)

    sonar =
      struct
      |> Map.get(:sonar)

    new_sonar = Map.put(sonar, :y, sonar[:y] - 1)
    new_struct = Map.put(struct, :sonar, new_sonar)
    update_set(set, index, new_struct)
  end

  defp decrease_position(set, :x, index) do
    struct = fetch_struct(set, index)

    sonar =
      struct
      |> Map.get(:sonar)

    new_sonar = Map.put(sonar, :x, sonar[:x] - 1)
    new_struct = Map.put(struct, :sonar, new_sonar)
    update_set(set, index, new_struct)
  end
end
