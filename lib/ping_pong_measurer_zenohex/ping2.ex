defmodule PingPongMeasurerZenohex.Ping2 do
  use GenServer

  require Logger

  @ping_max 10
  @message_type 'StdMsgs.Msg.String'
  @ping_topic 'ping_topic'
  @pong_topic 'pong_topic'
  @node_id_prefix 'ping_node'
  @monotonic_time_unit :microsecond

  alias PingPongMeasurerZenohex.Ping2.Measurer

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

  def init({session, node_counts, data_directory_path, from}) when is_integer(node_counts) do
    node_publishers = for i <- 0..(node_counts - 1) do
      pub_node_id = "#{@ping_topic}" <> "#{i}"
      sub_node_id = "#{@pong_topic}" <> "#{i}"

      node_id = @node_id_prefix ++ Integer.to_charlist(i)

      {:ok, publisher} = Session.declare_publisher(session, pub_node_id)

      Session.declare_subscriber(session, sub_node_id, fn message ->  callback(node_id, publisher, message, from) end)

      {node_id, {node_id, publisher, :pub}}
    end

    node_id_list = Enum.map(node_publishers, &elem(&1, 0))
    publishers = Enum.map(node_publishers, &elem(&1, 1))

    {:ok,
    %State{
      session: session,
      node_id_list: node_id_list,
      publishers: publishers,
      data_directory_path: data_directory_path
    }}
  end

  defp callback(node_id, publisher, message, from) do
    case Measurer.get_ping_counts(node_id) do

      @ping_max ->
        Measurer.stop_measurement(node_id, System.monotonic_time(@monotonic_time_unit))
        Measurer.reset_ping_counts(node_id)
        Process.send(from, :finished, _opts = [])

      _ ->
        ping(node_id, publisher, message)
    end
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
      {node_id, publisher, :pub} = publisher_taple

      Measurer.start_measurement(
        node_id,
        DateTime.utc_now(),
        System.monotonic_time(@monotonic_time_unit)
      )

      ping(node_id, publisher, payload)
    end)
    |> Enum.to_list()
  end

  def start_subscribing(from \\ self()) when is_pid(from) do
    GenServer.cast(__MODULE__, {:start_subscribing, from})
  end

  def handle_call(:get_node_id_list, _from, state) do
    {:reply, state.node_id_list, state}
  end

  def handle_call(:get_publishers, _from, state) do
    {:reply, state.publishers, state}
  end

  def handle_cast({:start_subscribing, from}, %State{} = state) do
    {:noreply, %State{state | from: from}}
  end

  def ping(node_id, publisher, payload_string) do
    Publisher.put(publisher, payload_string)
    Measurer.increment_ping_counts(node_id)
  end

  def sample_pub(publisher, _node_id, payload) do #when is_binary(payload) do
    sample_ping(publisher, payload)
  end

  defp sample_ping(publisher,payload) do
    Publisher.put(publisher,payload)
  end
end
