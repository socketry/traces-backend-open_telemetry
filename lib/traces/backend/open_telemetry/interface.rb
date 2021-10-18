# frozen_string_literal: true

# Copyright, 2021, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'opentelemetry'

require 'traces/context'
require_relative 'version'

module Traces
	module Backend
		module OpenTelemetry
			# Provides a backend that writes data to OpenTelemetry.
			# See <https://github.com/open-telemetry/opentelemetry-ruby> for more details.
			TRACER = ::OpenTelemetry.tracer_provider.tracer(Traces::Backend::OpenTelemetry.name, Traces::Backend::OpenTelemetry::VERSION)
			
			module Interface
				def trace(name, attributes: nil, &block)
					span = TRACER.start_span(name, attributes: attributes.transform_keys(&:to_s))
					
					begin
						if block.arity.zero?
							yield
						else
							yield span
						end
					rescue Exception => error
						span&.record_exception(error)
						span&.status = ::OpenTelemetry::Traces::Status.error("Unhandled exception of type: #{error.class}")
						raise
					ensure
						span&.finish
					end
				end
				
				def trace_context=(context)
					span_context = ::OpenTelemetry::Traces::SpanContext.new(
						trace_id: context.trace_id,
						span_id: context.parent_id,
						trace_flags: ::OpenTelemetry::Traces::TracesFlags.from_byte(context.flags),
						tracestate: context.state,
						remote: context.remote?
					)
					
					span = ::OpenTelemetry::Trace.non_recording_span(span_context)
					
					return ::OpenTelemetry::Trace.context_with_span(span)
				end
				
				def trace_context(span = ::OpenTelemetry::Trace.current_span)
					if span_context = span.context
						state = baggage.values(context: span.context)
						
						return Context.new(
							span_context.trace_id,
							span_context.span_id,
							span_context.trace_flags,
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