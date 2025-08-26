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
			
			# Provides the interface implementation for OpenTelemetry tracing backend.
			module Interface
				# Creates a trace span with the given name and attributes.
				# @parameter name [String] The name of the trace span.
				# @parameter attributes [Hash | Nil] Optional attributes to attach to the span.
				# @yields {|span| ...} The block to execute within the trace span.
				# @returns [Object] The result of the block execution.
				def trace(name, attributes: nil, &block)
					TRACER.in_span(name, attributes: attributes&.transform_keys(&:to_s), &block)
				end
				
				# Sets the current trace context.
				# @parameter context [Traces::Context | Nil] The trace context to set as current.
				def trace_context=(context)
					if context
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
				end
				
				# Checks if there is currently an active trace span.
				# @returns [Boolean] `true` if there is an active trace span, `false` otherwise.
				def active?
					# Check if there's a real active trace using OpenTelemetry's INVALID span:
					::OpenTelemetry::Trace.current_span != ::OpenTelemetry::Trace::Span::INVALID
				end
				
				# Gets the current trace context from the active span.
				# @parameter span [OpenTelemetry::Trace::Span] The span to extract context from, defaults to current span.
				# @returns [Traces::Context | Nil] The trace context, or `nil` if no active trace.
				def trace_context(span = ::OpenTelemetry::Trace.current_span)
					# Return nil if no active trace (using INVALID span check):
					return nil if span == ::OpenTelemetry::Trace::Span::INVALID
					
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
				
				# Gets the current OpenTelemetry context.
				# @returns [OpenTelemetry::Context] The current OpenTelemetry context.
				def current_context
					::OpenTelemetry::Context.current
				end
				
				# Executes code within the given context or attaches the context.
				# @parameter context [OpenTelemetry::Context] The context to use.
				# @yields {|| ...} Optional block to execute within the context.
				# @returns [Object] The result of the block if given, otherwise the detach token.
				def with_context(context)
					if block_given?
						::OpenTelemetry::Context.with_current(context) do
							yield
						end
					else
						::OpenTelemetry::Context.attach(context)
					end
				end
				
				# Injects trace context into headers for propagation.
				# @parameter headers [Hash | Nil] Optional headers hash to inject into, defaults to new hash.
				# @parameter context [OpenTelemetry::Context | Nil] Optional context to inject, defaults to current context.
				# @returns [Hash | Nil] The headers with injected trace context, or `nil` if no injection occurred.
				def inject(headers = nil, context = nil)
					context ||= ::OpenTelemetry::Context.current
					headers ||= Hash.new
					
					count = headers.count
					
					::OpenTelemetry.propagation.inject(headers, context: context)
					
					if count == headers.count
						# No injection was performed, so return nil:
						headers = nil
					end
					
					return headers
				end
				
				# Extracts trace context from headers.
				# @parameter headers [Hash] The headers to extract trace context from.
				# @returns [OpenTelemetry::Context] The extracted context.
				def extract(headers)
					::OpenTelemetry.propagation.extract(headers)
				end
			end
		end
		
		Interface = OpenTelemetry::Interface
	end
end
