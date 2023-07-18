defmodule SamplePing2 do
  use GenServer

  require Logger

  @ping_max 10
  @message_type 'StdMsgs.Msg.String'
  @ping_topic 'ping_topic'
  @pong_topic 'pong_topic'
  @node_id_prefix 'ping_node'
  @monotonic_time_unit :microsecond

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

  def init(node_counts) do
    ping_node_publishers = for i <- 0..(node_counts - 1) do
      pub_node_id = "#{@ping_topic}" <> "#{i}"
      sub_node_id = "#{@pong_topic}" <> "#{i}"

      node_id = @node_id_prefix ++ Integer.to_charlist(i)
      session = Zenohex.open
      {:ok, publisher} = Session.declare_publisher(session, pub_node_id)

      session = Zenohex.open
      Session.declare_subscriber(session, sub_node_id, fn message ->  callback(message, "ping") end)

      {node_id, {String.to_charlist(pub_node_id), publisher, :pub}}
    end

    ping_node_id_list = Enum.map(ping_node_publishers, &elem(&1, 0))
    ping_publishers = Enum.map(ping_node_publishers, &elem(&1, 1))

    # Enum.map(ping_publishers, fn publisher_taple ->
    #   {_node_id, publisher, :pub} = publisher_taple
#
    #   Publisher.put(publisher, "ping_message") end
    #   # ping(node_id, publisher, String.to_charlist(payload)
    #   )
    simple_enum_publish(ping_publishers, "test")

    {:ok, %State{
      node_id_list: ping_node_id_list,
      publishers: ping_publishers,
    }}
  end

  defp callback(message, ping_pong) do
    IO.inspect ping_pong <> " recieved message: " <> message
  end

  def get_publishers do
    GenServer.call(__MODULE__, :get_publishers)
  end

  def flow_publish(publishers, payload) when is_binary(payload) do
    publishers
    |> Flow.from_enumerable(max_demand: 1, stages: Enum.count(publishers))
    |> Flow.map(fn publisher_taple ->
      {node_id, publisher, :pub} = publisher_taple

      # Measurer.start_measurement(
      #   node_id,
      #   DateTime.utc_now(),
      #   System.monotonic_time(@monotonic_time_unit)
      # )

      ping(node_id, publisher, String.to_charlist(payload))
    end)
    |> Enum.to_list()
    Logger.info("publishing")
  end

  def enum_publish(publishers, payload) when is_binary(payload) do
    publishers
    |> Enum.map(fn {node_id, publisher, :pub} ->
      ping(node_id, publisher, String.to_charlist(payload))
    end)
    Logger.info("publishing")
  end

  def simple_enum_publish(publishers, payload) when is_binary(payload) do
    publishers
    |> Enum.map(fn p ->
      {_node_id, publisher, :pub} = p
      Publisher.put(publisher, payload)
    end)
    # Logger.info("publishing")
  end

  def mock_enum_publish(publishers, payload) when is_binary(payload) do
    Enum.map(publishers, fn publisher_taple ->
    {_node_id, publisher, :pub} = publisher_taple
    Publisher.put(publisher, payload) end
    # ping(node_id, publisher, String.to_charlist(payload)
    )
  end


  def handle_call(:get_publishers, _from, state) do
    IO.inspect "publishers counts: " <> "#{Enum.count(state.publishers)}"
    {:reply, state.publishers, state}
  end

  def ping(_node_id, publisher, payload_charlist) do
    Publisher.put(publisher, payload_charlist)
    # Measurer.increment_ping_counts(node_id)
  end

  def enum_start_ping_pong(payload) do
    get_publishers()
    |> enum_publish(payload)
  end

  def flow_start_ping_pong(payload) do
    get_publishers()
    |> enum_publish(payload)
  end
end
