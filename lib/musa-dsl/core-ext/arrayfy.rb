require_relative 'deep-copy'

module Musa
  module Extension
    module Arrayfy
      refine Object do
        def arrayfy(size: nil, default: nil)
          if size
            size.times.collect do
              nil? ? default : self
            end
          else
            nil? ? [] : [self]
          end
        end
      end

      # TODO add a refinement for Hash? Should receive a list parameter with the ordered keys

      refine Array do
        def arrayfy(size: nil, default: nil)
          if size
            DeepCopy::DeepCopy.copy_singleton_class_modules(
                self,
                (self * (size / self.size + ((size % self.size).zero? ? 0 : 1) )).take(size))
          else
            self.clone
          end.map! { |value| value.nil? ? default : value }
        end
      end
    end
  end
end
