require_relative 'deep-copy'

module Musa
  module Extension
    module Hashify
      refine Object do
        def hashify(keys:, default: nil)
          keys.collect do |key|
            [ key,
              if nil?
                default
              else
                self
              end ]
          end.to_h
        end
      end

      refine Array do
        def hashify(keys:, default: nil)
          values = clone
          keys.collect do |key|
            value = values.shift
            [ key,
              value.nil? ? default : value ]
          end.to_hash
        end
      end

      refine Hash do
        def hashify(keys:, default: nil)
          keys.collect do |key|
            value = self[key]
            [ key,
              value.nil? ? default : value ]
          end.to_h
              .tap {|_| DeepCopy::DeepCopy.copy_singleton_class_modules(self, _) }
        end
      end
    end
  end
end
