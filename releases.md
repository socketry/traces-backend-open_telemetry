# Releases

## Unreleased

### New Context Propagation Interface

This release adds comprehensive support for OpenTelemetry's context propagation system, enabling efficient inter-process and intra-process tracing with full W3C compliance.

  - `Traces.current_context` - Capture the current trace context for local propagation between execution contexts (threads, fibers).
  - `Traces.with_context(context)` - Execute code within a specific trace context, with automatic restoration when used with blocks.
  - `Traces.inject(headers = nil, context = nil)` - Inject W3C Trace Context and Baggage headers into a headers hash for distributed propagation.
  - `Traces.extract(headers)` - Extract trace context from W3C Trace Context headers.

## v0.2.0

  - Prefer to use `Tracer#in_span`.

## v0.1.0

  - Complete implementation of traces backend for OpenTelemetry.
