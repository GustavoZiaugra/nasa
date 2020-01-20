defmodule NasaTest do
  use ExUnit.Case
  doctest Nasa
  import ExUnit.CaptureIO

  describe "Nasa.run/1" do
    test "when path is valid and output is equal expected" do
      assert capture_io(fn ->
               Nasa.run("test/fixtures/template_positions.txt")
             end) == "1 3 N\n5 1 E\n"
    end

    test "when path is invalid" do
      assert_raise ArgumentError, "Your file may not exist!", fn ->
        Nasa.run("path")
      end
    end
  end
end
