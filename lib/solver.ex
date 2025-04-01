defmodule Solver do
  require Explorer.DataFrame

  defp encode_result(result) do
    result
    |> Enum.map(fn
      :green -> "g"
      :yellow -> "y"
      :grey -> "b"
    end)
    |> Enum.join("")
  end

  def init(file_path, output_path) do
    words = CsvLoader.load_file(file_path) |> Enum.map(fn row -> row["word"] end)

    # for each word in words, calculate wordle result matrix

    matrix =
      for guess <- words, word <- words do
        IO.puts("guess: #{guess} vs word: #{word}")

        %{
          guess: guess,
          word: word,
          result: Wordle.analyse_only_color(%{guess: guess, word: word}) |> encode_result()
        }
      end

    file = output_path |> File.open!([:write, :utf8])
    matrix |> CSV.encode(headers: true) |> Enum.to_list() |> Enum.each(&IO.write(file, &1))

    matrix
  end

  def load_dataframe(file_path) do
    Explorer.DataFrame.from_csv!(file_path)
  end
end
