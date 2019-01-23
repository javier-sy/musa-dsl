class Object
  def arrayfy
    if nil?
      []
    else
      [self]
    end
  end
end

class Array
  def arrayfy
    self
  end
end
