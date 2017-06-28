module SpreadBase # :nodoc:

  # Represents the abstraction of a cell; values and their types are merged into a single entity.
  #
  class Cell

    attr_accessor :value

    def initialize(value)
      @value = value
    end

    def ==(other)
      other.is_a?(Cell) && @value == other.value
    end

  end

end
