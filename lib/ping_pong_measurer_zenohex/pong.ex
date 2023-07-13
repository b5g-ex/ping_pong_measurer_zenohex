defmodule PingPongMeasurerZenohex.Pong do
  use GenServer

  require Logger

  alias PingPongMeasurerZenohex.Utils

  # def start_link({_, node_index} = args_tuple) do
  #   GenServer.start_link(__MODULE__, args_tuple,
  #     name: Utils.get_process_name(__MODULE__, node_index)
  #   )
  # end

  def start_link(args_tuple) do
    GenServer.start_link(__MODULE__, args_tuple, name: __MODULE__)
  end


  def init({session,node_counts}) do #when is_integer(node_index) do
    """
    {:ok, node_id} =
      Rclex.ResourceServer.create_node(context, 'pong_node' ++ to_charlist(node_index))

    ping_topic = 'ping' ++ to_charlist(node_index)
    pong_topic = 'pong' ++ to_charlist(node_index)

    {:ok, subscriber} = Rclex.Node.create_subscriber(node_id, 'StdMsgs.Msg.String', ping_topic)
    {:ok, publisher} = Rclex.Node.create_publisher(node_id, 'StdMsgs.Msg.String', pong_topic)

    Rclex.Subscriber.start_subscribing([subscriber], context, fn msg ->
      recv_msg = Rclex.Msg.read(msg, 'StdMsgs.Msg.String')
      Logger.info('ping: ' ++ recv_msg.data)

      Rclex.Publisher.publish([publisher], [Utils.create_payload(recv_msg.data)])
    end)

    {:ok, nil}
    """
    {:ok, publisher} = Session.declare_publisher(session, "zenoh-rs-pong")
    subscriber = Session.declare_subscriber(session, "zenoh-rs-ping", fn m -> callback(m,publisher) end)
    {:ok,{publisher,subscriber}}
  end

  def callback(m,publisher) do #送り返す
    pong(publisher,m)
    IO.inspect(m)
  end

  def pong(publisher, payload)  do
    Publisher.put(publisher, payload)
    #Measurer.increment_ping_counts(node_id)
  end
end
