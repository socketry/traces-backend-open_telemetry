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
	
	def my_span
		Traces.trace('my_span') {|span| return span}
	end
	
	def my_context
		Traces.trace('my_context') {|span| return Traces.trace_context}
	end

	def my_span_and_context
		Traces.trace('my_span_and_context') {|span| return span, Traces.trace_context}
	end
end

describe Traces::Backend::OpenTelemetry do
	let(:instance) {MyClass.new}
	
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
	
	describe OpenTelemetry::Trace::Span do
		let(:span) {instance.my_span}
		
		it "can assign name" do
			span.name = "new_name"
		end
		
		it "can assign attributes" do
			span["my_key"] = "tag_value"
		end
	end
	
	describe OpenTelemetry::Trace::SpanContext do
		let(:span_and_context) {instance.my_span_and_context}
		let(:span) {span_and_context.first}
		let(:context) {span_and_context.last}

		with '#trace_context' do
			it "has a valid trace id" do
				expect(context).to have_attributes(
					trace_id: be != nil
				)
			end
		end
		
		with '#trace_context=' do
			it "can update trace context" do
				Traces.trace_context = context
				
				span = instance.my_span
				
				expect(span.context).to have_attributes(
					trace_id: be == context.trace_id,
				)
				
				# It seems like OpenTelemetry doesn't really do anything in the testing environment, so we can't really check the parent_id?
				# expect(span).to have_attributes(
				# 	parent_id: be == context.parent_id
				# )
			end
		end
	end
end
