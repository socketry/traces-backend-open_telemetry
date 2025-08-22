# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2025, by Samuel Williams.

require "opentelemetry"
require "traces/context"

module Traces
	module Backend
		module OpenTelemetry
			class Context < Traces::Context
				def initialize(*arguments, **options, context: nil)
					super(*arguments, **options)
					@context = context
				end
				
				attr :context
			end
		end
	end
end