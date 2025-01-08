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
	let(:instance) { MyClass.new }
	
	it "has a version number" do
		expect(Traces::Backend::OpenTelemetry::VERSION).not.to be == nil
	end
	
	it "can invoke trace wrapper" do
		expect(Traces::Backend::OpenTelemetry::TRACER).to receive(:start_span)
		
		instance.my_method(10)
	end
	
	describe OpenTelemetry::Trace::Span do
		it "can yield an open telemetry span" do
			expect(instance.my_span).to be_a(OpenTelemetry::Trace::Span)
		end
	end
	
	describe "span and context" do
		let(:span_and_context) {instance.my_span_and_context}
		let(:span) {span_and_context.first}
		let(:context) {span_and_context.last}
		let(:new_context) {
			Traces::Context.new(
				SecureRandom.uuid,
				SecureRandom.uuid,
				0,
				nil,
				remote: false
			)
		}
		
		it "can provide a trace context with a trace_id" do
			expect(context).to have_attributes(trace_id: be != nil)
			expect(span.context.trace_id).to be == context.trace_id
		end
		
		describe "#trace_context=" do
			it "can update the trace context" do
				expect(Traces.trace_context).to be != new_context
				
				Traces.trace_context = new_context
				expect(instance.my_span.context).to have_attributes(
					trace_id: be == new_context.trace_id,
					span_id: be == new_context.parent_id
				)
			end
		end
	end
end
