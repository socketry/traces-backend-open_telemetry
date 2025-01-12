# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2025, by Samuel Williams.

require "opentelemetry"

require "traces/context"
require_relative "version"

module Traces
	module Backend
		module OpenTelemetry
			# Provides a backend that writes data to OpenTelemetry.
			# See <https://github.com/open-telemetry/opentelemetry-ruby> for more details.
			TRACER = ::OpenTelemetry.tracer_provider.tracer(Traces::Backend::OpenTelemetry.name, Traces::Backend::OpenTelemetry::VERSION)
			
			module Interface
				def trace(name, attributes: nil, &block)
					TRACER.in_span(name, attributes: attributes&.transform_keys(&:to_s), &block)
				end
				
				def trace_context=(context)
					span_context = ::OpenTelemetry::Trace::SpanContext.new(
						trace_id: context.trace_id,
						span_id: context.parent_id,
						trace_flags: ::OpenTelemetry::Trace::TraceFlags.from_byte(context.flags),
						tracestate: context.state,
						remote: context.remote?
					)
					
					span = ::OpenTelemetry::Trace.non_recording_span(span_context)
					context = ::OpenTelemetry::Trace.context_with_span(span)
					::OpenTelemetry::Context.attach(context)
				end
				
				def trace_context(span = ::OpenTelemetry::Trace.current_span)
					if span_context = span.context
						flags = 0
						
						if span_context.trace_flags.sampled?
							flags |= Context::SAMPLED
						end
						
						return Context.new(
							span_context.trace_id,
							span_context.span_id,
							flags,
							span_context.tracestate,
							remote: span_context.remote?
						)
					end
				end
			end
		end
		
		Interface = OpenTelemetry::Interface
	end
end
