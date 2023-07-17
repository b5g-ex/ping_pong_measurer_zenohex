defmodule PingPongMeasurerZenohex.Pong do
  use GenServer

  require Logger

  @ping_topic 'ping_topic'
  @pong_topic 'pong_topic'

  def start_link(args_tuple) do
    GenServer.start_link(__MODULE__, args_tuple, name: __MODULE__)
  end

  def init({session, node_counts}) when is_integer(node_counts) do
    for i <- 0..(node_counts - 1) do
      {:ok, publisher} = Session.declare_publisher(session, "#{@pong_topic}" <> "#{i}")

      Session.declare_subscriber(session, "#{@ping_topic}" <> "#{i}", fn message ->
        Publisher.put(publisher, message)
      end)
    end

    {:ok, nil}
  end
end
