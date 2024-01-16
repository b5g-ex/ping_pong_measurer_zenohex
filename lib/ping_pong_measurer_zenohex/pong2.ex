defmodule PingPongMeasurerZenohex.Pong2 do
  use GenServer

  require Logger

  @message_type 'StdMsgs.Msg.String'
  @ping_topic 'ping_topic'
  @pong_topic 'pong_topic'


  def start_link(args_tuple) do
    GenServer.start_link(__MODULE__, args_tuple, name: __MODULE__)
  end

  def init({session, node_counts}) when is_integer(node_counts) do
    publishers = for i <- 0..(node_counts - 1) do
      sub_node_id = "#{@ping_topic}" <> "#{i}"
      pub_node_id = "#{@pong_topic}" <> "#{i}"

      {:ok, publisher} = Session.declare_publisher(session, pub_node_id)
      Session.declare_subscriber(session, sub_node_id, fn message -> callback(publisher, message) end)
      # FIX: IO.puts message to callback(publisher, message)
      publisher
    end

    {:ok, nil}
  end

  defp callback(publisher, message) do
    Publisher.put(publisher, message)
  end
end
