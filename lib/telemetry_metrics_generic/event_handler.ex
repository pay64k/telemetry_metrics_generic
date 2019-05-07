defmodule TelemetryMetricsGeneric.EventHandler do
  @moduledoc false

  alias Telemetry.Metrics

  @spec attach(
          [Metrics.t()],
          reporter :: pid(),
          callback :: any
        ) :: [
          :telemetry.handler_id()
        ]
  def attach(metrics, reporter, callback) do
    metrics_by_event = Enum.group_by(metrics, & &1.event_name)

    for {event_name, metrics} <- metrics_by_event do
      handler_id = handler_id(event_name, reporter)

      :ok =
        :telemetry.attach(handler_id, event_name, &__MODULE__.handle_event/4, %{
          metrics:    metrics,
          callback:   callback
        })

      handler_id
    end
  end

  @spec detach([:telemetry.handler_id()]) :: :ok
  def detach(handler_ids) do
    for handler_id <- handler_ids do
      :telemetry.detach(handler_id)
    end

    :ok
  end

  def handle_event(_event, measurements, _metadata, %{
         metrics:  metrics,
        #  prefix:   prefix,
         callback: callback
       }) do
    packets =
      for metric <- metrics do
        case fetch_measurement(metric, measurements) do
          {:ok, value} ->
            {metric, value}

          :error ->
            :nopublish
        end
      end
      |> Enum.filter(fn l -> l != :nopublish end)

    case packets do
      [] ->
        :ok

      packets ->
        publish_metrics(packets, callback)
    end
  end

  @spec handler_id(:telemetry.event_name(), reporter :: pid) :: :telemetry.handler_id()
  defp handler_id(event_name, reporter) do
    {__MODULE__, reporter, event_name}
  end

  @spec fetch_measurement(Metrics.t(), :telemetry.event_measurements()) ::
          {:ok, number()} | :error
  defp fetch_measurement(%Metrics.Counter{}, _measurements) do
    # For counter, we can ignore the measurements and just use 0.
    {:ok, 0}
  end

  defp fetch_measurement(metric, measurements) do
    value =
      case metric.measurement do
        fun when is_function(fun, 1) ->
          fun.(measurements)

        key ->
          measurements[key]
      end

    cond do
      is_float(value) ->
        # The StatsD metrics we implement support only numerical values.
        {:ok, round(value)}

      is_integer(value) ->
        {:ok, value}

      true ->
        :error
    end
  end

  @spec publish_metrics([any], any) :: :ok
  defp publish_metrics(data, callback) do
    Enum.each(data, fn {metric, value} ->
      callback.(metric, value)
    end)
  end
end
