defmodule MeasurementHelper do
  require Logger

  alias PingPongMeasurerZenohex.Data

  def start_measurement(node_counts \\ 1, payload_bytes \\ 10, measurement_times \\ 10) do
    data_directory_path = prepare_data_directory!(node_counts, payload_bytes, measurement_times)

    context = Zenohex.open()

    # PingPongMeasurerZenohex.start_os_info_measurement(data_directory_path)
    PingPongMeasurerZenohex.start_ping_processes(context, node_counts, data_directory_path, self())
    PingPongMeasurerZenohex.start_ping_measurer(data_directory_path)

    for _ <- 1..measurement_times do
      PingPongMeasurerZenohex.start_ping_pong(String.duplicate("a", payload_bytes))
      PingPongMeasurerZenohex.wait_until_all_nodes_finished(node_counts)
    end

    PingPongMeasurerZenohex.stop_ping_measurer()
    PingPongMeasurerZenohex.stop_ping_processes()
    # PingPongMeasurerZenohex.stop_os_info_measurement()
  end

  def sample_start_measurement(node_counts \\ 1, payload_bytes \\ 10, measurement_times \\ 10)
      when node_counts in [1, 10, 100] and payload_bytes in [10, 100, 1000, 10000] do
    from = self()
    context = Zenohex.open()
    data_directory_path = prepare_data_directory!(node_counts, payload_bytes, measurement_times)
    PingPongMeasurerZenohex.start_ping_processes(context, node_counts, data_directory_path, from)
    PingPongMeasurerZenohex.sample_start_process(node_counts,"Hello?")
    PingPongMeasurerZenohex.stop_ping_processes()
  end


  defp prepare_data_directory!(node_counts, payload_bytes, measurement_times) do
    data_directory_path =
      Application.get_env(:ping_pong_measurer_zenohex, :data_directory_path) ||
        raise """
        You have to configure :data_directory_path in config.exs
        ex) config :ping_pong_measurer_Zenohex, :data_directory_path, "path/to/directory"
        """

    dt_string = Data.datetime_to_string(DateTime.utc_now())
    directory_name = "#{dt_string}_pc#{node_counts}_pb#{payload_bytes}_mt#{measurement_times}"
    data_directory_path = Path.join(data_directory_path, directory_name)

    File.mkdir_p!(data_directory_path)
    data_directory_path
  end
end
