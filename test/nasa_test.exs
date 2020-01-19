defmodule NasaTest do
  use ExUnit.Case
  doctest Nasa

  describe "validates if script returns expected output" do
    _output = Nasa.run("test/fixtures/positions.txt")
  end
end
