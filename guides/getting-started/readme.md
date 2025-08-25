# Getting Started

This guide explains how to get started with `traces-backend-open_telemetry` to send application traces to OpenTelemetry.

## Installation

Add the gem to your project:

```bash
$ bundle add traces-backend-open_telemetry
```

## Usage

You will need to configure OpenTelemetry appropriately, e.g.:

```bash
$ bundle add opentelemetry-exporter-otlp
```

Then, you can emit traces:

```ruby
require "opentelemetry/sdk"

# You should do this in your environment configuration.
ENV["TRACES_BACKEND"] ||= "traces/backend/open_telemetry"

require "traces"

OpenTelemetry::SDK.configure

Traces.trace("main") do
	puts "Hello World"
end
```
