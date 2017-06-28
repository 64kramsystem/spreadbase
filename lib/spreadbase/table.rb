module SpreadBase # :nodoc:

  # Represents the abstraction of a table and its contents.
  #
  # The max width of the table is 1024 cells - the last one being 'AMJ'.
  #
  # Row indexing follows the ruby semantics:
  # - negative indexes represent an access starting from the end of an array
  # - out-of-bounds access will return nil where a row is accessed as a whole, and raise an error when a cell has to be accessed.
  #
  class Table

    include SpreadBase::Helpers

    attr_accessor :name

    # Array of style names; nil when not associated to any column width.
    #
    attr_accessor :column_width_styles # :nodoc:

    # _params_:
    #
    # +name+::                       (required) Name of the table
    # +raw_data+::                   (Array.new) 2d matrix of the data. if not empty, the rows need to be all of the same size
    #
    def initialize(name, raw_data=[])
      raise "Table name required" if name.nil? || name == ''

      @name                = name
      self.data            = raw_data
      @column_width_styles = []
    end

    def data=(the_data)
      @data = the_data.map { | the_row | array_to_cells(the_row) }
    end

    def data(options={})
      @data.map { | the_row | the_row.map { | cell | cell_to_value(cell, options) } }
    end

    # Access a cell value.
    #
    # _params_:
    #
    # +column_indentifier+::         either an int (0-based) or the excel-format identifier (AA...); limited to the given row size.
    # +row_index+::                  int (0-based). see notes about the rows indexing.
    #
    # _returns_ the value, which is automatically converted to the Ruby data type.
    #
    def [](column_identifier, row_index, options={})
      the_row = row(row_index, options)

      column_index = decode_column_identifier(column_identifier)

      check_column_index(the_row, column_index)

      the_row[ column_index ]
    end

    # Writes a value in a cell.
    #
    # _params_:
    #
    # +column_indentifier+::         either an int (0-based) or the excel-format identifier (AA...); limited to the given row size.
    # +row_index+::                  int (0-based). see notes about the rows indexing.
    # +value+::                      value
    #
    def []=(column_identifier, row_index, value)
      check_row_index(row_index)

      the_row      = @data[ row_index ]
      column_index = decode_column_identifier(column_identifier)

      check_column_index(the_row, column_index)

      the_row[ column_index ] = value_to_cell(value)
    end

    # Returns an array containing the values of a single row.
    #
    # _params_:
    #
    # +row_index+::                  int or range (0-based). see notes about the rows indexing.
    #
    def row(row_index, options={})
      check_row_index(row_index)

      if row_index.is_a?(Range)
        @data[ row_index ].map { | row | cells_to_array(row, options) }
      else
        cells_to_array(@data[ row_index ], options)
      end
    end

    # Deletes a row.
    #
    # This operation won't modify the column width styles in any case.
    #
    # _params_:
    #
    # +row_index+::                  int or range (0-based). see notes about the rows indexing.
    #
    # _returns_ the deleted row[s]
    #
    def delete_row(row_index)
      check_row_index(row_index)

      deleted_cells = @data.slice!(row_index)

      if row_index.is_a?(Range)
        deleted_cells.map { | row | cells_to_array(row) }
      else
        cells_to_array(deleted_cells)
      end
    end

    # Inserts a row.
    #
    # This operation won't modify the column width styles in any case.
    #
    # _params_:
    #
    # +row_index+::                  int (0-based). must be between 0 and (including) the table rows size.
    # +row+::                        array of values. if the table is not empty, must have the same size of the table width.
    #
    def insert_row(row_index, row)
      check_row_index(row_index, :allow_append => true)

      cells = array_to_cells(row)

      @data.insert(row_index, cells)
    end

    # This operation won't modify the column width styles in any case.
    #
    def append_row(row)
      insert_row(@data.size, row)
    end

    # Returns an array containing the values of a single column.
    #
    # WATCH OUT! This method doesn't have the range restrictions that axis indexes generally has, that is, it's possible to access a column outside the boundaries of the rows - it will return nil for each of those values.
    #
    # _params_:
    #
    # +column_indentifier+::         for single access, us either an int (0-based) or the excel-format identifier (AA...).
    #                                when int, follow the same idea of the rows indexing (ruby semantics).
    #                                for multiple access, use a range either of int or excel-format identifiers - pay attention, because ( 'A'..'c' ) is not semantically correct.
    #                                interestingly, ruby letter ranges convention is the same as the excel columns one.
    #
    def column(column_identifier, options={})
      if column_identifier.is_a?(Range)
        min_index = decode_column_identifier(column_identifier.min)
        max_index = decode_column_identifier(column_identifier.max)

        (min_index..max_index).map do | column_index |
          @data.map do | the_row |
            cell = the_row[ column_index ]

            cell_to_value(cell, options)
          end
        end
      else
        column_index = decode_column_identifier(column_identifier)

        @data.map do | the_row |
          cell = the_row[ column_index ]

          cell_to_value(cell, options)
        end
      end
    end

    # Deletes a column.
    #
    # See Table#column for the indexing notes.
    #
    # _params_:
    #
    # +column_indentifier+::         See Table#column
    #
    # _returns_ the deleted column
    #
    def delete_column(column_identifier)
      if column_identifier.is_a?(Range)
        min_index = decode_column_identifier(column_identifier.min)
        max_index = decode_column_identifier(column_identifier.max)

        reverse_result = max_index.downto(min_index).map do | column_index |
          @data.map do | row |
            cell = row.slice!(column_index)

            cell_to_value(cell)
          end
        end

        reverse_result.reverse
      else
        column_index = decode_column_identifier(column_identifier)

        @column_width_styles.slice!(column_index)

        @data.map do | row |
          cell = row.slice!(column_index)

          cell_to_value(cell)
        end
      end
    end

    # Inserts a column.
    #
    # WATCH OUT! This method doesn't have the range restrictions that axis indexes generally has, that is, it's possible to insert a column outside the boundaries of the rows - it will fill the cells in the middle with nils..
    #
    # _params_:
    #
    # +column_indentifier+::         either an int (0-based) or the excel-format identifier (AA...).
    #                                when int, follow the same idea of the rows indexing (ruby semantics).
    # +column+::                     array of values. if the table is not empty, it must have the same size of the table height.
    #
    def insert_column(column_identifier, column)
      raise "Inserting column size (#{ column.size }) different than existing columns size (#{ @data.size })" if @data.size > 0 && column.size != @data.size

      column_index = decode_column_identifier(column_identifier)

      @column_width_styles.insert(column_index, nil)

      if @data.size > 0
        @data.zip(column).each do | row, value |
          cell = value_to_cell(value)

          row.insert(column_index, cell)
        end
      else
        @data = column.map do | value |
          [ value_to_cell(value) ]
        end
      end

    end

    def append_column(column)
      column_index = @data.size > 0 ? @data.first.size : 0

      insert_column(column_index, column)
    end

    # _returns_ a matrix representation of the tables, with the values being separated by commas.
    #
    def to_s(options={})
      pretty_print_rows(data, options)
    end

    private

    def array_to_cells(the_row)
      the_row.map { | value | value_to_cell(value) }
    end

    def value_to_cell(value)
      value.is_a?(Cell) ? value : Cell.new(value)
    end

    def cells_to_array(cells, options={})
      cells.map { | cell | cell_to_value(cell, options) }
    end

    def cell_to_value(cell, options={})
      as_cell = options[ :as_cell ]

      if as_cell
        cell
      else
        cell.value if cell
      end
    end

    # Check that row index points to an existing record, or, in case of :allow_append,
    # point to one unit above the last row.
    #
    # _options_:
    #
    # +allow_append+::      Allow pointing to one unit above the last row.
    #
    def check_row_index(row_index, options={})
      allow_append = options [ :allow_append ]

      positive_limit = allow_append ? @data.size : @data.size - 1

      row_index = row_index.max if row_index.is_a?(Range)

      raise "Invalid row index (#{ row_index }) - allowed 0 to #{ positive_limit }" if row_index < 0 || row_index > positive_limit
    end

    def check_column_index(row, column_index)
      raise "Invalid column index (#{ column_index }) for the given row - allowed 0 to #{ row.size - 1 }" if column_index >= row.size
    end

    # Accepts either an integer, or a MoFoBase26BisexNumber.
    #
    # Raises an error for invalid identifiers/indexes.
    #
    # _returns_ a 0-based decimal number.
    #
    def decode_column_identifier(column_identifier)
      if column_identifier.is_a?(Fixnum)
        raise "Negative column indexes not allowed: #{ column_identifier }" if column_identifier < 0

        column_identifier
      else
        letters       = column_identifier.upcase.chars.to_a
        upcase_a_ord  = 65

        raise "Invalid letter for in column identifier (allowed 'a/A' to 'z/Z')" if letters.any? { | letter | letter < 'A' || letter > 'Z' }

        base_10_value = letters.inject(0) do | sum, letter |
          letter_ord = letter.unpack('C').first
          sum * 26 + (letter_ord - upcase_a_ord + 1)
        end

        base_10_value -= 1

        # -1 is an empty string
        #
        raise "Invalid literal column identifier (allowed 'A' to 'AMJ')" if base_10_value < 0 || 1023 < base_10_value

        base_10_value
      end
    end

  end

end
