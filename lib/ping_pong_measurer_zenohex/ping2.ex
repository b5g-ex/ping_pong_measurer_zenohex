defmodule PingPongMeasurerZenohex.Ping2 do
  use GenServer

  require Logger

  @ping_max 100
  @message_type 'StdMsgs.Msg.String'
  @ping_topic 'ping_topic'
  @pong_topic 'pong_topic'
  @node_id_prefix 'ping_node'
  @monotonic_time_unit :microsecond

  alias PingPongMeasurerZenohex.Utils
  alias PingPongMeasurerZenohex.Ping2.Measurer

  defmodule State do
    defstruct session: nil, #FIX? context を session に置き換えたがいらないはず
              node_counts: nil,
              publishers: [],
              subscribers: [],
              #data_directory_path: "",
              from: nil
  end

  def start_link(args_tuple) do
    GenServer.start_link(__MODULE__, args_tuple, name: __MODULE__)
  end

  def init({node_counts}) when is_integer(node_counts) do
    #def init({node_counts, data_directory_path}) when is_integer(node_counts) do

    session = Zenohex.open
     #FIX: only for one session (in the future multi pubs and subs)
    publishers= []
    subscribers = []

    for i <- 1..node_counts do
      {:ok, publisher} = Session.declare_publisher(session, "zenoh-rs-ping#{i}")
      subscriber = Session.declare_subscriber(session, "zenoh-rs-pong#{i}" , fn m -> callback(m) end)
      #IO.puts(publisher)
      publishers  = publishers ++ [publisher]
      subscribers = subscribers ++ [subscriber]

      #publishers  = [publisher]
      #subscribers = [subscriber]

     #node_id_list = ['a']
    end

     {:ok,
     %State{
       session: session,
       node_counts: node_counts,
       publishers: publishers,
       subscribers: subscribers,
       #data_directory_path: data_directory_path
     }}
  end

  def callback(m) do #送り返す
    IO.inspect(m)
  end

  def get_node_id_list() do
    GenServer.call(__MODULE__, :get_node_id_list)
  end

  def get_publishers do
    GenServer.call(__MODULE__, :get_publishers)
  end

  # def publish(publishers, payload) when is_binary(payload) do
  #   publishers
  #   |> Flow.from_enumerable(max_demand: 1, stages: Enum.count(publishers))
  #   |> Flow.map(fn publisher ->
  #     {node_id, _topic, :pub} = publisher

  #     Measurer.start_measurement(
  #       node_id,
  #       DateTime.utc_now(),
  #       System.monotonic_time(@monotonic_time_unit)
  #     )

  #     ping(node_id, publisher, String.to_charlist(payload))
  #   end)
  #   |> Enum.to_list()
  # end

  def publish(publishers, payload) when is_binary(payload) do
    publishers
    |> Flow.from_enumerable(max_demand: 1, stages: Enum.count(publishers))
    |> Flow.map(fn publisher ->
      {node_counts, _topic, :pub} = publisher

      Measurer.start_measurement(
        node_counts,
        DateTime.utc_now(),
        System.monotonic_time(@monotonic_time_unit)
      )

      ping(publisher, String.to_charlist(payload))
    end)
    |> Enum.to_list()
  end

  def pub(publishers,node_counts, payload) do #when is_binary(payload) do
    for i <- 1..node_counts do
      publisher = Enum.at(publishers,i)
      ping(publisher,payload)
    end
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

  # def handle_cast({:start_subscribing, from}, %State{} = state) do
  #   for i <- 1..state.node_counts  do
  #     # {_, @ping_topic ++ publisher_index, :pub} = publisher = Enum.at(state.publishers, index)
  #     # {_, @pong_topic ++ subscriber_index, :sub} = subscriber = Enum.at(state.subscribers, index)
  #     publisher = Enum.at(state.publishers,i)
  #     subscriber = Enum.at(state.subscribers,i)

  #     # assert index
  #     #^publisher_index = subscriber_index


  #     # FIX: Rclex.Subscriber.start_subscribing の Zenohex 版をつくる
  #     Zenohex.Subscriber.start_subscribing(subscriber, state.session, fn message ->
  #       # FIX: log message
  #       # message = Zenohex.Msg.read(message, @message_type)
  #       Logger.debug('pong: ' ++ message)

  #       case Measurer.get_ping_counts(node_id) do
  #         0 ->
  #           # NOTE: 初回は外部から実行されインクリメントされるので、ここには来ない
  #           #       ここに来る場合は同一ネットワーク内に Pong が複数起動していないか確認すること
  #           raise RuntimeError

  #          @ping_max ->
  #           Measurer.stop_measurement(node_id, System.monotonic_time(@monotonic_time_unit))
  #           Logger.debug("#{inspect(Measurer.get_measurement_time(node_id))} msec")
  #           Measurer.reset_ping_counts(node_id)
  #           Process.send(from, :finished, _opts = [])

  #         _ ->
  #           ping(publisher, message)
  #       end
  #     end)
  #   end

  #   {:noreply, %State{state | from: from}}
  # end

  def ping(publisher, payload)  do
    Publisher.put(publisher, payload)
    #Measurer.increment_ping_counts(node_id)
  end
end
