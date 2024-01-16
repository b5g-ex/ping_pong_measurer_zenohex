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
    # {:ok, node_id_list} = Rclex.ResourceServer.create_nodes(context, 'pong_node', node_counts)

    # {:ok, subscribers} =
    #   Rclex.Node.create_subscribers(node_id_list, @message_type, @ping_topic, :multi)

    # {:ok, publishers} =
    #   Rclex.Node.create_publishers(node_id_list, @message_type, @pong_topic, :multi)

    # for {_node_id, index} <- Enum.with_index(node_id_list) do
    #   subscriber = Enum.at(subscribers, index)
    #   publisher = Enum.at(publishers, index)

    #   Rclex.Subscriber.start_subscribing([subscriber], context, fn message ->
    #     message = Rclex.Msg.read(message, @message_type)
    #     Logger.debug('ping: ' ++ message.data)

    #     Rclex.Publisher.publish([publisher], [Utils.create_payload(message.data)])
    #   end)
    # end

    # {:ok, nil}


    publishers = for i <- 0..(node_counts - 1) do
      sub_node_id = "#{@ping_topic}" <> "#{i}"
      pub_node_id = "#{@pong_topic}" <> "#{i}"

      {:ok, publisher} = Session.declare_publisher(session, pub_node_id)
      Session.declare_subscriber(session, sub_node_id, fn message -> callback(publisher, message) end)
      # FIX: IO.puts message to callback(publisher, message)
      publisher
    end

    # {:ok, publisher} = Session.declare_publisher(session, "#{@pong_topic}" <> "#{0}")
    # Session.declare_subscriber(session, "#{@ping_topic}" <> "#{0}", fn message -> callback(publisher, message) end)

    # {:ok, %State{
    #   publishers: publishers,
    #   subscribers: subscribers
    #   }}

    {:ok, nil}
  end

  defp callback(publisher, message) do
    Publisher.put(publisher, message)
  end
end
