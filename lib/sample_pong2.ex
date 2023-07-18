defmodule SamplePong2 do
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
    _pong_node_publishers = for i <- 0..(node_counts - 1) do
      sub_node_id = "#{@ping_topic}" <> "#{i}"
      pub_node_id = "#{@pong_topic}" <> "#{i}"

      node_id = @node_id_prefix ++ Integer.to_charlist(i)
      session = Zenohex.open
      {:ok, publisher} = Session.declare_publisher(session, pub_node_id)

      session = Zenohex.open
      Session.declare_subscriber(session, sub_node_id, fn message ->  callback_pong(message, "pong", publisher) end)

      {node_id, {String.to_charlist(pub_node_id), publisher, :pub}}
    end

    {:ok, nil}
  end

  def callback_pong(message, ping_pong, publisher) do
    IO.inspect ping_pong <> " recieved message: " <> message
    Publisher.put(publisher, message)
    IO.inspect ping_pong <> " published"
  end
end
