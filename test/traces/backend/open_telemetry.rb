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
		Traces.trace("my_span") {|span| return span}
	end
	
	def my_context
		Traces.trace("my_context") {|span| return Traces.trace_context}
	end
	
	def my_span_and_context
		Traces.trace("my_span_and_context") {|span| return span, Traces.trace_context}
	end
end

describe Traces::Backend::OpenTelemetry do
	let(:instance) {MyClass.new}
	
	it "has a version number" do
		expect(Traces::Backend::OpenTelemetry::VERSION).not.to be == nil
	end
	
	it "can invoke trace wrapper" do
		expect(Traces::Backend::OpenTelemetry::TRACER).to receive(:start_span).with_options(have_keys(
			attributes: be == {"argument" => 10}
		))
		
		instance.my_method(10)
	end
	
	it "can invoke trace wrapper without attributes" do
		expect(Traces::Backend::OpenTelemetry::TRACER).to receive(:start_span)
		
		instance.my_method_without_attributes(10)
	end
	
	it "can invoke trace wrapper with exception" do
		expect(Traces::Backend::OpenTelemetry::TRACER).to receive(:start_span)
		
		expect do
			instance.my_method_with_exception
		end.to raise_exception(RuntimeError, message: be == "Error")
	end
	
	describe OpenTelemetry::Trace::Span do
		it "can assign name while span is active" do
			span_name = nil
			
			Traces.trace("test") do |span|
				span.name = "new_name"
				span_name = span.name
			end
			
			expect(span_name).to be == "new_name"
		end
		
		it "can assign attributes while span is active" do
			Traces.trace("test") do |span|
				# Both syntaxes should work without error:
				span["my_key"] = "tag_value"
				span.set_attribute("another_key", "another_value")
				
				# Test passes if no exception is raised:
				expect(span).to be_a(::OpenTelemetry::Trace::Span)
			end
		end
	end
	
	describe OpenTelemetry::Trace::SpanContext do
		let(:span_and_context) {instance.my_span_and_context}
		let(:span) {span_and_context.first}
		let(:context) {span_and_context.last}
		
		with "#trace_context" do
			it "has a valid trace id" do
				expect(context).to have_attributes(
					trace_id: be != nil
				)
			end
		end
		
		with "#trace_context=" do
			it "can update trace context" do
				Traces.trace_context = context
				
				span = instance.my_span
				
				expect(span.context).to have_attributes(
					trace_id: be == context.trace_id,
				)
				
				expect(span).to have_attributes(
					parent_span_id: be == context.parent_id
				)
			end
		end
	end
	
	describe "Context Propagation Methods" do
		with "#current_context" do
			it "returns current OpenTelemetry context" do
				current = Traces.current_context
				expect(current).to be_a(::OpenTelemetry::Context)
			end
			
			it "returns different contexts in different spans" do
				context1 = nil
				context2 = nil
				
				Traces.trace("span1") do
					context1 = Traces.current_context
				end
				
				Traces.trace("span2") do
					context2 = Traces.current_context
				end
				
				# Contexts should be different objects (different spans):
				expect(context1).not.to be_equal(context2)
			end
		end
		
		with "#with_context" do
			it "executes block within specified context" do
				original_context = Traces.current_context
				test_context = ::OpenTelemetry::Context.empty
				executed = false
				
				Traces.with_context(test_context) do
					executed = true
					expect(::OpenTelemetry::Context.current).to be_equal(test_context)
				end
				
				expect(executed).to be == true
				# Context should be restored after block:
				expect(::OpenTelemetry::Context.current).to be_equal(original_context)
			end
			
			it "permanently sets context when called without block" do
				original_context = Traces.current_context
				test_context = ::OpenTelemetry::Context.empty
				
				token = Traces.with_context(test_context)
				expect(::OpenTelemetry::Context.current).to be_equal(test_context)
				
				# Clean up by detaching:
				::OpenTelemetry::Context.detach(token)
			end
		end
		
		with "#inject" do
			it "injects trace context into headers" do
				headers = {}
				
				Traces.trace("test") do
					Traces.inject(headers)
				end
				
				expect(headers).to have_keys(
					"traceparent" => be_a(String)
				)
				
				traceparent = headers["traceparent"]
				expect(traceparent).to be =~ /^00-[0-9a-f]{32}-[0-9a-f]{16}-[0-9a-f]{2}$/
			end
			
			it "creates new headers hash when none provided" do
				Traces.trace("test") do
					headers = Traces.inject()
					expect(headers).to be_a(Hash)
					expect(headers["traceparent"]).to be =~ /^00-[0-9a-f]{32}-[0-9a-f]{16}-[0-9a-f]{2}$/
				end
			end
			
			it "uses specific context when provided" do
				headers = {}
				
				Traces.trace("test") do
					specific_context = Traces.current_context
					Traces.inject(headers, specific_context)
					expect(headers["traceparent"]).to be =~ /^00-[0-9a-f]{32}-[0-9a-f]{16}-[0-9a-f]{2}$/
				end
			end
			
			it "returns nil when no headers provided and no active trace" do
				# Clear any active trace:
				::OpenTelemetry::Context.clear
				
				result = Traces.inject()
				expect(result).to be == nil
			end
			
			it "returns nil when headers provided but no active trace" do
				# Clear any active trace:
				::OpenTelemetry::Context.clear
				headers = {"existing" => "value"}
				
				result = Traces.inject(headers)
				expect(result).to be == nil
				# Original headers should remain unchanged:
				expect(headers["existing"]).to be == "value"
				expect(headers.key?("traceparent")).to be == false
			end
		end
		
		with "#extract" do
			it "extracts context from headers" do
				headers = {
					"traceparent" => "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"
				}
				
				context = Traces.extract(headers)
				expect(context).to be_a(::OpenTelemetry::Context)
				
				# Verify we can use the extracted context:
				Traces.with_context(context) do
					span = ::OpenTelemetry::Trace.current_span
					# Convert binary trace_id to hex for comparison:
					trace_id_hex = span.context.trace_id.unpack1("H*")
					expect(trace_id_hex).to be == "4bf92f3577b34da6a3ce929d0e0e4736"
				end
			end
			
			it "returns original context for invalid headers" do
				headers = {"traceparent" => "invalid"}
				original_context = ::OpenTelemetry::Context.current
				
				result = Traces.extract(headers)
				expect(result).to be_equal(original_context)
			end
			
			it "handles missing headers gracefully" do
				headers = {}
				original_context = ::OpenTelemetry::Context.current
				
				result = Traces.extract(headers)
				expect(result).to be_equal(original_context)
			end
		end
		
		with "round-trip inject/extract" do
			it "preserves context through inject and extract cycle" do
				original_headers = {}
				
				# Create a trace and inject it:
				Traces.trace("test") do
					Traces.inject(original_headers)
				end
				
				expect(original_headers).to have_keys(
					"traceparent" => be_a(String)
				)
				
				# Extract the context:
				extracted_context = Traces.extract(original_headers)
				expect(extracted_context).to be_a(::OpenTelemetry::Context)
				
				# Use extracted context to create another trace:
				Traces.with_context(extracted_context) do
					span = ::OpenTelemetry::Trace.current_span
					expect(span.context.remote?).to be == true
				end
			end
		end
	end
end
