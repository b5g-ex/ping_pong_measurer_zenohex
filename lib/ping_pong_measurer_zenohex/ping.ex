defmodule PingPongMeasurerZenohex.Ping do
  use GenServer

  require Logger

  @ping_max 10
  @message_type 'StdMsgs.Msg.String'
  @ping_topic 'ping_topic'
  @pong_topic 'pong_topic'
  @node_id_prefix 'ping_node'
  @monotonic_time_unit :microsecond

  alias PingPongMeasurerZenohex.Measurer

  defmodule State do
    defstruct session: nil,
              node_id_list: [],
              publishers: [],
              data_directory_path: "",
              from: nil
  end

  def start_link(args_tuple) do
    GenServer.start_link(__MODULE__, args_tuple, name: __MODULE__)
  end

  def init({session, node_counts, data_directory_path}) when is_integer(node_counts) do
    node_id_list = Enum.to_list(0..(node_counts - 1))

    publishers =
      for node_id <- node_id_list do
        {:ok, publisher} = Session.declare_publisher(session, "#{@ping_topic}" <> "#{node_id}")

        {node_id, publisher}
      end

    {:ok,
     %State{
       session: session,
       node_id_list: node_id_list,
       publishers: publishers,
       data_directory_path: data_directory_path
     }}
  end

  def start() do
    GenServer.call(__MODULE__, :start)
  end

  def handle_call(:start, _from, state) do
    state.publishers
    |> Enum.each(fn publisher ->
      Publisher.put(publisher, state.payload)
    end)

    {:noreply, state}
  end

  def get_node_id_list() do
    GenServer.call(__MODULE__, :get_node_id_list)
  end

  def get_publishers do
    GenServer.call(__MODULE__, :get_publishers)
  end

  def publish(publishers, payload) when is_binary(payload) do
    publishers
    |> Flow.from_enumerable(max_demand: 1, stages: Enum.count(publishers))
    |> Flow.map(fn publisher_taple ->
      {node_id, publisher} = publisher_taple

      Measurer.start_measurement(
        node_id,
        DateTime.utc_now(),
        System.monotonic_time(@monotonic_time_unit)
      )

      ping(node_id, publisher, payload)
    end)
    |> Enum.to_list()
  end

  def handle_call(:start_subscribing, from, %State{} = state) do
    for {node_id, publisher} <- state.publishers do
      Session.declare_subscriber(state.session, "#{@pong_topic}" <> "#{node_id}", fn message ->
        count = Measurer.get_ping_counts(node_id)

        cond do
          count == 0 ->
            # NOTE: 初回は外部から実行されインクリメントされるので、ここには来ない
            #       ここに来る場合は同一ネットワーク内に Pong が複数起動していないか確認すること
            raise RuntimeError

          count >= @ping_max ->
            Measurer.stop_measurement(node_id, System.monotonic_time(@monotonic_time_unit))
            Logger.debug("#{inspect(Measurer.get_measurement_time(node_id))} msec")
            Measurer.reset_ping_counts(node_id)
            {pid, _} = from
            Process.send(pid, :finished, _opts = [])

          true ->
            ping(node_id, publisher, message)
        end
      end)
    end

    {:reply, %State{state | from: from}, %State{state | from: from}}
  end

  def start_subscribing(from \\ self()) when is_pid(from) do
    GenServer.call(__MODULE__, :start_subscribing)
  end

  def handle_call(:get_node_id_list, _from, state) do
    {:reply, state.node_id_list, state}
  end

  def handle_call(:get_publishers, _from, state) do
    {:reply, state.publishers, state}
  end

  def ping(node_id, publisher, payload) do
    Publisher.put(publisher, payload)
    Measurer.increment_ping_counts(node_id)
  end
end
