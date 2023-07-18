defmodule PingPongMeasurerZenohex.Pong do
  use GenServer

  require Logger

  @message_type 'StdMsgs.Msg.String'
  @ping_topic 'ping_topic'
  @pong_topic 'pong_topic'


  def start_link(args_tuple) do
    GenServer.start_link(__MODULE__, args_tuple, name: __MODULE__)
  end

  def init({session, node_counts}) when is_integer(node_counts) do
    {:ok, publisher} = Session.declare_publisher(session, "#{@pong_topic}" <> "#{0}")
    Session.declare_subscriber(session, "#{@ping_topic}" <> "#{0}", fn message -> callback(publisher, message) end)
    # FIX: IO.puts message to callback(publisher, message)
    Logger.info("#{0}")
    {:ok, nil}
  end

  defp callback(publisher, message) do
    Logger.info(publisher)
    Logger.info(message)
    Publisher.put(publisher, message)
  end
end
