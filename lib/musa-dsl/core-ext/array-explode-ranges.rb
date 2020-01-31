class Array
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
