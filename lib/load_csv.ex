defmodule CsvLoader do
  def load_file(file_path) do
    file_path
    |> File.stream!()
    |> CSV.decode!(headers: true)
    |> Enum.map(fn row -> row end)
  end
end
