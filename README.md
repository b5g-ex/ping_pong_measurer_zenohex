# PingPongMeasurerZenohex
This repository contains the code for performance measurement of the [Zenoh](https://github.com/eclipse-zenoh/zenoh) Elixir binding, [Zenohex](https://github.com/b5g-ex/zenohex). The code is specifically designed for conducting ping-pong communication tests.

## Overview

Zenohex is a communication middleware that provides Elixir bindings for Zenoh. This benchmark focuses on evaluating the performance of Zenohex in parallel execution through ping-pong communication scenarios.

## how To Use
- start pong nodes
```bash
iex -S mix
iex> PingPongMeasurerZenohex.start_pong_processes(Zenohex.open(), 10)
```
In this example, the number of pong nodes are 10

- start ping nodes in another terminal
```bash
iex -S mix
iex>MeasurementHelper.start_measurement(10, 100, 1)
```
node_counts is 10, payload_bytes is 100, measurement_times is 1

data is stored in ./data folder
