defmodule PingPongMeasurerZenohex.Pong2 do
  use GenServer

  require Logger

  @message_type 'StdMsgs.Msg.String'
  @ping_topic 'ping_topic'
  @pong_topic 'pong_topic'

  alias PingPongMeasurerZenohex.Utils


  defmodule State do
    defstruct publishers: [],
              subscribers: []
              #data_directory_path: "",
  end

  def start_link(args_tuple) do
    GenServer.start_link(__MODULE__, args_tuple, name: __MODULE__)
  end

  def init({session,node_counts}) when is_integer(node_counts) do

  #   session = Zenohex.open


  # def callback(m) do #送り返す
  #     ""
  # end
    publishers= []
    subscribers = []
    for i <- 1..node_counts do
      {:ok, publisher} = Session.declare_publisher(session, "zenoh-rs-pong#{i}")
      subscriber = Session.declare_subscriber(session, "zenoh-rs-ping#{i}", fn m -> m |> callback(publisher) end)
      #IO.puts(subscriber)
      publishers  = publishers ++ [publisher]
      subscribers = subscribers ++ [subscriber]

    end



    # for {_node_id, index} <- Enum.with_index(node_id_list) do
    #   subscriber = Enum.at(subscribers, index)
    #   publisher = Enum.at(publishers, index)
    #   payload = "payload_string"

    #   Publisher.put(publisher, payload)
    # end
    {:ok,
     %State{
       publishers: publishers,
       subscribers: subscribers,
       #data_directory_path: data_directory_path
     }}
  end

  def callback(m,publisher) do #送り返す
    pong(publisher,m)
  end

  def pong(publisher, payload)  do
    Publisher.put(publisher, payload)
    #Measurer.increment_ping_counts(node_id)
  end

end
