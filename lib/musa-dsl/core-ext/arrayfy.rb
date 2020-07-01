module Musa
  module Extension
    module Arrayfy
      refine Object do
        def arrayfy(size: nil)
          if size
            size.times.collect { self }
          else
            if nil?
              []
            else
              [self]
            end
          end
        end
      end

      refine Array do
        def arrayfy(size: nil)
          if size
            (self * (size / self.size + ((size % self.size).zero? ? 0 : 1) )).take(size)
          else
            self.clone
          end
        end
      end
    end
  end
end
