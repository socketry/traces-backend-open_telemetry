# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

ENV["TRACES_BACKEND"] ||= "traces/backend/open_telemetry"

require "covered/sus"
include Covered::Sus

require "opentelemetry/sdk"
OpenTelemetry::SDK.configure
