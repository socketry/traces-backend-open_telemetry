# frozen_string_literal: true

require_relative "lib/traces/backend/open_telemetry/version"

Gem::Specification.new do |spec|
	spec.name = "traces-backend-open_telemetry"
	spec.version = Traces::Backend::OpenTelemetry::VERSION
	
	spec.summary = "A traces backend for Open Telemetry."
	spec.authors = ["Samuel Williams"]
	spec.license = "MIT"
	
	spec.cert_chain  = ["release.cert"]
	spec.signing_key = File.expand_path("~/.gem/release.pem")
	
	spec.homepage = "https://github.com/socketry/traces-backend-open_telemetry"
	
	spec.metadata = {
		"source_code_uri" => "https://github.com/socketry/traces-backend-open_telemetry.git",
	}
	
	spec.files = Dir.glob(["{lib}/**/*", "*.md"], File::FNM_DOTMATCH, base: __dir__)
	
	spec.required_ruby_version = ">= 3.2"
	
	spec.add_dependency "opentelemetry-api", "~> 1.0"
	spec.add_dependency "traces", "~> 0.10"
end
