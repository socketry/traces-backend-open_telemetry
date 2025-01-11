# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021-2025, by Samuel Williams.

require "traces"

class MyClass
	def my_method(argument)
	end
end

Traces::Provider(MyClass) do
	def my_method(argument)
		Traces.trace("my_method", attributes: {argument: argument}) {super}
	end
	
	def my_method_without_attributes(arguments)
		Traces.trace("my_method_without_attributes") {}
	end
	
	def my_method_with_exception
		Traces.trace("my_method_with_exception") {raise "Error"}
	end
end

describe Traces::Backend::OpenTelemetry do
	it "has a version number" do
		expect(Traces::Backend::OpenTelemetry::VERSION).not.to be == nil
	end
	
	it "can invoke trace wrapper" do
		instance = MyClass.new
		
		expect(Traces::Backend::OpenTelemetry::TRACER).to receive(:start_span).with_options(have_keys(
			attributes: be == {"argument" => 10}
		))
		
		instance.my_method(10)
	end
	
	it "can invoke trace wrapper without attributes" do
		instance = MyClass.new
		
		expect(Traces::Backend::OpenTelemetry::TRACER).to receive(:start_span)
		
		instance.my_method_without_attributes(10)
	end
	
	it "can invoke trace wrapper with exception" do
		instance = MyClass.new
		
		expect(Traces::Backend::OpenTelemetry::TRACER).to receive(:start_span)
		
		expect do
			instance.my_method_with_exception
		end.to raise_exception(RuntimeError, message: be == "Error")
	end
end
