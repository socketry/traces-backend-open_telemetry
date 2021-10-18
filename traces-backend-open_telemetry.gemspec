
require_relative "lib/traces/backend/open_telemetry/version"

Gem::Specification.new do |spec|
	spec.name = "traces-backend-open_telemetry"
	spec.version = Traces::Backend::OpenTelemetry::VERSION
	
	spec.summary = "A traces backend for Open Telemetry."
	spec.authors = ["Samuel Williams"]
	spec.license = "MIT"
	
	spec.cert_chain  = ['release.cert']
	spec.signing_key = File.expand_path('~/.gem/release.pem')
	
	spec.homepage = "https://github.com/socketry/traces-backend-open_telemetry"
	
	spec.files = Dir.glob('{lib}/**/*', File::FNM_DOTMATCH, base: __dir__)
	
	spec.add_dependency "traces", "~> 0.4.0"
	spec.add_dependency "opentelemetry-api", "~> 1.0"
	
	spec.add_development_dependency "rspec", "~> 3.0"
end
