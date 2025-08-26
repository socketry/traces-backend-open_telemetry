# Traces::Backend::OpenTelemetry

A backend for sending traces to OpenTelemetry.

[![Development Status](https://github.com/socketry/traces-backend-open_telemetry/workflows/Test/badge.svg)](https://github.com/socketry/traces-backend-open_telemetry/actions?workflow=Test)

## Installation

``` shell
$ bundle add traces-backend-open_telemetry
```

## Usage

Please see the [project documentation](https://github.com/socketry/traces-backend-open_telemetry) for more details.

  - [Getting Started](https://github.com/socketry/traces-backend-open_telemetryguides/getting-started/index) - This guide explains how to get started with `traces-backend-open_telemetry` to send application traces to OpenTelemetry.

## Releases

Please see the [project releases](https://github.com/socketry/traces-backend-open_telemetryreleases/index) for all releases.

### v0.4.0

  - Fixed `Traces.active?` to correctly return `false` when there is no active trace, instead of always returning `true`.
  - Fixed `Traces.trace_context` to return `nil` when there is no active trace, instead of returning invalid Context objects.

### v0.3.0

  - [New Context Propagation Interface](https://github.com/socketry/traces-backend-open_telemetryreleases/index#new-context-propagation-interface)

### v0.2.0

  - Prefer to use `Tracer#in_span`.

### v0.1.0

  - Complete implementation of traces backend for OpenTelemetry.

## Contributing

We welcome contributions to this project.

1.  Fork it.
2.  Create your feature branch (`git checkout -b my-new-feature`).
3.  Commit your changes (`git commit -am 'Add some feature'`).
4.  Push to the branch (`git push origin my-new-feature`).
5.  Create new Pull Request.

### Developer Certificate of Origin

In order to protect users of this project, we require all contributors to comply with the [Developer Certificate of Origin](https://developercertificate.org/). This ensures that all contributions are properly licensed and attributed.

### Community Guidelines

This project is best served by a collaborative and respectful environment. Treat each other professionally, respect differing viewpoints, and engage constructively. Harassment, discrimination, or harmful behavior is not tolerated. Communicate clearly, listen actively, and support one another. If any issues arise, please inform the project maintainers.
