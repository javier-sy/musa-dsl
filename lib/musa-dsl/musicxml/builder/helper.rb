module Musa
  module MusicXML
    module Builder
      module Internal
        module Helper
          module NotImplemented
            def initialize(**_args); end

            def to_xml(io = nil, indent: nil)
              raise NotImplementedError, "#{self.class} not yet implemented. Ask Javier do his work!"
            end
          end

          module ToXML
            def to_xml(io = nil, indent: nil)
              io ||= StringIO.new
              indent ||= 0

              tabs = "\t" * indent

              _to_xml(io, indent: indent, tabs: tabs)

              io
            end

            private

            def _to_xml(io, indent:, tabs:); end
          end

          module HeaderToXML
            def header_to_xml(io = nil, indent: nil)
              io ||= StringIO.new
              indent ||= 0

              tabs = "\t" * indent

              _header_to_xml(io, indent: indent, tabs: tabs)

              io
            end

            private

            def _header_to_xml(io, indent:, tabs:); end
          end

          private

          def make_instance_if_needed(klass, hash_or_class_instance)
            case hash_or_class_instance
            when klass
              hash_or_class_instance
            when Hash
              klass.new **hash_or_class_instance
            when nil
              nil
            else
              raise ArgumentError, "#{hash_or_class_instance} is not a Hash, nor a #{klass.name} nor nil"
            end
          end

          def decode_bool_or_string_attribute(value, attribute, true_value = nil, false_value = nil)
            if value.is_a?(String) || value.is_a?(Numeric)
              "#{attribute}=\"#{value}\""
            elsif value.is_a?(TrueClass) && true_value
              "#{attribute}=\"#{true_value}\""
            elsif value.is_a?(FalseClass) && false_value
              "#{attribute}=\"#{false_value}\""
            else
              ''
            end
          end

          def decode_bool_or_string_value(value, true_value = nil, false_value = nil)
            if value.is_a?(String) || value.is_a?(Numeric)
              value
            elsif value.is_a?(TrueClass) && true_value
              true_value
            elsif value.is_a?(FalseClass) && false_value
              false_value
            else
              ''
            end
          end
        end
      end
    end
  end
end