module Musa
  module Series::Operations
    def split
      Splitter.new(self)
    end

    class Splitter
      include Series::Serie.with(source: true)
      include Enumerable

      private def has_source; true; end
      private def has_sources; false; end

      def initialize(source)
        self.source = source
        @series = {}

        init
      end

      def source=(serie)
        super
        @proxy.source = @source if @proxy
      end

      def _sources_resolved
        @proxy = SplitterProxy.new(@source)
      end

      def [](key_or_index)
        raise "Can't get a component because Splitter is a prototype. To get a component you need a Splitter instance." unless instance?

        if @series.key?(key_or_index)
          @series[key_or_index]
        else
          @series[key_or_index] = Split.new(@proxy, key_or_index)
        end
      end

      def each
        raise "Can't iterate because Splitter is in state '#{state}'. To iterate you need a Splitter in state 'instance'." unless instance?

        if block_given?
          if @proxy.hash_mode?
            @proxy.components.each do |key|
              yield [key, self[key]]
            end
          elsif @proxy.array_mode?
            @proxy.components.each do |index|
              yield self[index]
            end
          else
            # do nothing
          end
        else
          if @proxy.hash_mode?
            @proxy.components.collect { |key| [key, self[key]] }.each
          elsif @proxy.array_mode?
            @proxy.components.collect { |index| self[index] }.each
          else
            [].each
          end
        end
      end

      def to_hash
        if @proxy.hash_mode?
          @proxy.components.collect { |key| [key, self[key]] }.to_h
        else
          raise RuntimeError, 'Splitter is not based on Hash: can\'t convert to Hash'
        end
      end

      def to_ary
        if @proxy.array_mode?
          [].tap { |_| @proxy.components.each { |i| _[i] = self[i] } }
        else
          raise RuntimeError, 'Splitter is not based on Array: can\'t convert to Array'
        end
      end

      class SplitterProxy
        def initialize(hash_or_array_serie)
          @source = hash_or_array_serie
          infer_components
        end

        attr_reader :source

        def source=(hash_or_array_serie)
          @source = hash_or_array_serie
          infer_components
        end

        def hash_mode?; @hash_mode; end

        def array_mode?; @array_mode; end

        attr_reader :components

        def restart(key_or_index = nil)
          if key_or_index
            @asked_to_restart[key_or_index] = true
          else
            @components.each { |c| @asked_to_restart[c] = true }
          end

          if @asked_to_restart.values.all?
            @source.restart
            infer_components
          end
        end

        private def infer_components
          source = @source.instance
          sample = source.current_value || source.peek_next_value

          case sample
          when Array
            @components = (0..sample.size-1).to_a
            @values = []
            @array_mode = true
            @hash_mode = false
          when Hash
            @components = sample.keys.clone
            @values = {}
            @array_mode = false
            @hash_mode = true
          else
            @components = []
            @values = nil
            @array_mode = @hash_mode = false
          end

          @asked_to_restart = {}

          @components.each do |component|
            @asked_to_restart[component] = false
          end
        end

        def next_value(key_or_index)
          if @values[key_or_index].nil? || @values[key_or_index].empty?

            hash_or_array_value = @source.next_value

            case hash_or_array_value
            when Hash
              hash_or_array_value.each do |k, v|
                @values[k] ||= []
                @values[k] << v
              end
            when Array
              hash_or_array_value.each_index do |i|
                @values[i] ||= []
                @values[i] << hash_or_array_value[i]
              end
            end
          end

          if @values && !@values[key_or_index].nil?
            @values[key_or_index].shift
          else
            nil
          end
        end
      end

      private_constant :SplitterProxy

      class Split
        include Series::Serie.base

        def initialize(proxy, key_or_index)
          @proxy = proxy
          @key_or_index = key_or_index

          mark_as_instance!
        end

        private def _restart
          @proxy.restart(@key_or_index)
        end

        private def _next_value
          @proxy.next_value(@key_or_index)
        end
      end

      private_constant :Split
    end

    private_constant :Splitter
  end
end
