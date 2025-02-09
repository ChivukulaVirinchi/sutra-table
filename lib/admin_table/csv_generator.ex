defmodule AdminTable.CsvGenerator do
  alias NimbleCSV.RFC4180, as: CSV
  alias AdminTable.Repo

  def generate_csv(query, header_data) do
    timestamp = DateTime.utc_now()
      |> DateTime.to_string()
      |> String.replace([" ", ":", "."], "-")
      |> String.replace(~r/[^a-zA-Z0-9\-]/, "")
    temp_path = Path.join(System.tmp_dir!(), "export-#{timestamp}.csv")
    query = get_query(query)
    case stream_data_to_file(query, temp_path, header_data) do
      {:ok, _} -> {:ok, temp_path}
      error -> error
    end
  end

  def get_query(query) do
    qs = query
      |> String.trim_leading("#Ecto.Query<")
      |> String.trim_trailing(">")

    try do
      query =  Code.eval_string("""
      import Ecto.Query
      #{qs}
    """) |> elem(0)

    case query do
      %Ecto.Query{} -> query
     _ -> raise ArgumentError, "Invalid Ecto query string"
    end
    rescue
    CompileError -> raise ArgumentError, "Invalid Ecto query string"
      end
  end

  defp stream_data_to_file(query, path, header_data) do
    [header_keys, header_labels] = header_data

    atom_keys = Enum.map(header_keys, &String.to_atom/1)

    Repo.transaction(fn ->
      File.write!(path, CSV.dump_to_iodata([header_labels]))
      query
      |> Repo.stream(max_rows: 1000)
      |> Stream.map(fn row ->
              Enum.map(atom_keys, &Map.get(row, &1))
            end)
      |> Stream.chunk_every(1000)
      |> Stream.map(fn chunk ->
        if Process.whereis(:chunk_monitor) do
          send(:chunk_monitor, {:chunk, length(chunk)})
        end
        CSV.dump_to_iodata(chunk)
      end)
      |> Stream.each(&File.write!(path, &1, [:append]))
      |> Stream.run()
    end)
  end
end
