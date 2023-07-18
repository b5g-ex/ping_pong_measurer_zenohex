defmodule Sample do

  @ping_max 10
  @message_type 'StdMsgs.Msg.String'
  @ping_topic 'ping_topic'
  @pong_topic 'pong_topic'
  @node_id_prefix 'ping_node'
  @monotonic_time_unit :microsecond

  def ping(node_counts \\ 1) do

    node_publishers = for i <- 0..(node_counts - 1) do
      pub_node_id = "#{@ping_topic}" <> "#{i}"
      sub_node_id = "#{@pong_topic}" <> "#{i}"

      node_id = @node_id_prefix ++ Integer.to_charlist(i)
      session = Zenohex.open
      {:ok, publisher} = Session.declare_publisher(session, pub_node_id)

      session = Zenohex.open
      Session.declare_subscriber(session, pub_node_id, fn message ->  callback(message) end)

      {node_id, {String.to_charlist(pub_node_id), publisher, :pub}}

      Publisher.put(publisher, "Hello!")
    end

    # node_id_list = Enum.map(node_publishers, &elem(&1, 0))
    # publishers = Enum.map(node_publishers, &elem(&1, 1))



  end

  defp callback(message, ping_pong \\ "") do
    IO.inspect "sub callback"
    IO.inspect ping_pong
    IO.inspect message
  end

  def hetero_ping(node_counts \\ 1) do
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



    # for pong
    pong_node_publishers = for i <- 0..(node_counts - 1) do
      sub_node_id = "#{@ping_topic}" <> "#{i}"
      pub_node_id = "#{@pong_topic}" <> "#{i}"

      node_id = @node_id_prefix ++ Integer.to_charlist(i)
      session = Zenohex.open
      {:ok, publisher} = Session.declare_publisher(session, pub_node_id)

      session = Zenohex.open
      Session.declare_subscriber(session, sub_node_id, fn message ->  callback(message, "pong") end)

      {node_id, {String.to_charlist(pub_node_id), publisher, :pub}}
    end

    Enum.map(ping_publishers, fn publisher_taple ->
      {_node_id, publisher, :pub} = publisher_taple

      Publisher.put(publisher, "ping_message") end
      # ping(node_id, publisher, String.to_charlist(payload)
      )

    _pong_node_id_list = Enum.map(pong_node_publishers, &elem(&1, 0))
    pong_publishers = Enum.map(pong_node_publishers, &elem(&1, 1))

    Enum.map(pong_publishers, fn publisher_taple ->
      {_node_id, publisher, :pub} = publisher_taple

      Publisher.put(publisher, "pong_message") end
      # ping(node_id, publisher, String.to_charlist(payload)
      )

  end

  def one_ping_pong(node_counts \\ 1) do
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



    # for pong
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

    Enum.map(ping_publishers, fn publisher_taple ->
      {_node_id, publisher, :pub} = publisher_taple

      Publisher.put(publisher, "ping_message") end
      # ping(node_id, publisher, String.to_charlist(payload)
      )

  end

  def callback_pong(message, ping_pong, publisher) do
    IO.inspect "sub callback"
    IO.inspect ping_pong
    IO.inspect message
    Publisher.put(publisher, message)
  end
end
