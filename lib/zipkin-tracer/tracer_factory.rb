
module ZipkinTracer
  class TracerFactory
    def tracer(config)
      adapter = config.adapter

      tracer = case adapter
        when :json
          require 'zipkin-tracer/zipkin_json_tracer'
          options = { json_api_host: config.json_api_host, traces_buffer: config.traces_buffer, logger: config.logger }
          Trace::ZipkinJsonTracer.new(options)
        when :scribe
          require 'zipkin-tracer/careless_scribe'
          Trace::ZipkinTracer.new(CarelessScribe.new(config.scribe_server), config.scribe_max_buffer)
        when :kafka
          require 'zipkin-tracer/zipkin_kafka_tracer'
          Trace::ZipkinKafkaTracer.new(zookeepers: config.zookeeper)
        else
          Trace::NullTracer.new
      end
      Trace.tracer = tracer

      # TODO: move this to the TracerBase and kill scribe tracer
      ip_format = config.adapter == :json ? :string : :i32
      Trace.default_endpoint = Trace::Endpoint.make_endpoint(
        nil, # auto detect hostname
        config.service_port,
        service_name(config.service_name),
        ip_format
      )
      tracer
    end

    # Use the Domain environment variable to extract the service name, otherwise use the default config name
    # TODO: move to the config object
    def service_name(default_name)
      ENV["DOMAIN"].to_s.empty? ? default_name : ENV["DOMAIN"].split('.').first
    end
  end
end