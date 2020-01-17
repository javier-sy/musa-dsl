class Array
  def repeat_to_size(new_size)
    pos = -1
    new_size -= 1

    new_array = clone
    new_array << self[(pos += 1) % size] while (pos + size) < new_size

    new_array
  end

  def explode_ranges
    array = []

    each do |element|
      if element.is_a? Range
        element.to_a.each { |element| array << element }
      else
        array << element
      end
    end

    array
  end
end
