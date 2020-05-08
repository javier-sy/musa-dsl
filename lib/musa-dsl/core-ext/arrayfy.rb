class Object
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

class Array
  def arrayfy(size: nil)
    if size
      (self * (size / self.size + ((size % self.size).zero? ? 0 : 1) )).take(size)
    else
      self
    end
  end
end
