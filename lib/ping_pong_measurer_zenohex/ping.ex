defmodule PingPongMeasurerZenohex.Ping do
  use GenServer

  require Logger

  alias PingPongMeasurerZenohex.Utils

  @ping_counts_max 100

  defmodule State do
    defstruct node_id: nil, publisher: nil, payload: "", ping_counts: 0, measurements: []
  end

  defmodule Measurement do
    defstruct measurement_time: nil, send_time: nil, recv_time: nil

    @type t() :: %__MODULE__{
            measurement_time: DateTime.t(),
            send_time: integer(),
            recv_time: integer()
          }
  end

  def start_link({_, node_index} = args_tuple) do
    GenServer.start_link(__MODULE__, args_tuple,
      name: Utils.get_process_name(__MODULE__, node_index)
    )
  end

  def init({context, node_index}) when is_integer(node_index) do
    """ from rclex
    {:ok, node_id} =
      Rclex.ResourceServer.create_node(context, 'ping_node' ++ to_charlist(node_index))

    ping_topic = 'ping' ++ to_charlist(node_index)
    pong_topic = 'pong' ++ to_charlist(node_index)

    {:ok, publisher} = Rclex.Node.create_publisher(node_id, 'StdMsgs.Msg.String', ping_topic)
    {:ok, subscriber} = Rclex.Node.create_subscriber(node_id, 'StdMsgs.Msg.String', pong_topic)


    Rclex.Subscriber.start_subscribing([subscriber], context, fn msg ->
      recv_msg = Rclex.Msg.read(msg, 'StdMsgs.Msg.String')

      Logger.info('pong: ' ++ recv_msg.data)
      publish(node_index)
    end)

    payload = Utils.create_payload('message')

    {:ok, %State{node_id: node_id, publisher: publisher, payload: payload}}
    """

    session = Zenohex.open

    {:ok, publisher} = Session.declare_publisher(session, "demo/example/zenoh-rs-pub")
    Publisher.put(publisher, " (sample) Hello zenoh?")
    Session.declare_subscriber(session, "demo/example/zenoh-rs-pub", fn m -> IO.inspect(m) end)

    {:ok, %State{publisher: publisher}}
  end

  def publish(node_index \\ 1) do
    GenServer.call(Utils.get_process_name(__MODULE__, node_index), :publish)
  end

  def handle_call(
        :publish,
        _from,
        %State{ping_counts: ping_counts, measurements: measurements} = state
      ) do
    state =
      case ping_counts do
        0 ->
          measurement = %Measurement{
            measurement_time: DateTime.utc_now(),
            send_time: System.monotonic_time(:microsecond)
          }

          ping(state)
          %State{state | ping_counts: ping_counts + 1, measurements: [measurement | measurements]}

        @ping_counts_max ->
          [h | t] = measurements
          measurement = %Measurement{h | recv_time: System.monotonic_time(:microsecond)}
          IO.inspect("#{inspect((measurement.recv_time - measurement.send_time) / 1000)} msec")

          %State{state | ping_counts: 0, measurements: [measurement | t]}

        _ ->
          ping(state)
          %State{state | ping_counts: ping_counts + 1}
      end

    {:reply, :ok, state}
  end

  defp ping(%State{} = state) do
    Rclex.Publisher.publish([state.publisher], [state.payload])
  end
end
