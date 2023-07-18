defmodule SamplePing2 do
  use GenServer

  require Logger

  @ping_max 10
  @message_type 'StdMsgs.Msg.String'
  @ping_topic 'ping_topic'
  @pong_topic 'pong_topic'
  @node_id_prefix 'ping_node'
  @monotonic_time_unit :microsecond

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

    _ping_node_id_list = Enum.map(ping_node_publishers, &elem(&1, 0))
    ping_publishers = Enum.map(ping_node_publishers, &elem(&1, 1))

    Enum.map(ping_publishers, fn publisher_taple ->
      {_node_id, publisher, :pub} = publisher_taple

      Publisher.put(publisher, "ping_message") end
      # ping(node_id, publisher, String.to_charlist(payload)
      )

    {:ok, nil}
  end

  defp callback(message, ping_pong) do
    IO.inspect ping_pong <> " recieved message: " <> message
  end
end
