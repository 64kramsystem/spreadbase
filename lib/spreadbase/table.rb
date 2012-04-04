# encoding: UTF-8

=begin
Copyright 2012 Saverio Miroddi saverio.pub2 <a-hat!> gmail.com

This file is part of SpreadBase.

SpreadBase is free software: you can redistribute it and/or modify it under the
terms of the GNU Lesser General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

SpreadBase is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License along
with SpreadBase.  If not, see <http://www.gnu.org/licenses/>.
=end

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

    attr_accessor :name, :data

    # Array of style names; nil when not associated to any column width.
    #
    attr_accessor :column_width_styles # :nodoc:

    # _params_:
    #
    # +name+::                       (required) Name of the table
    # +data+::                       (Array.new) 2d matrix of the data. if not empty, the rows need to be all of the same size
    #
    def initialize( name, data=[] )
      raise "Table name required" if name.nil? || name == ''

      @name                = name
      @data                = data
      @column_width_styles = []
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
    def []( column_identifier, row_index )
      row          = row( row_index )
      column_index = decode_column_identifier( column_identifier )

      check_column_index( row, column_index )

      row[ column_index ]
    end

    # Writes a value in a cell.
    #
    # _params_:
    #
    # +column_indentifier+::         either an int (0-based) or the excel-format identifier (AA...); limited to the given row size.
    # +row_index+::                  int (0-based). see notes about the rows indexing.
    # +value+::                      value
    #
    def []=( column_identifier, row_index, value )
      row          = row( row_index )
      column_index = decode_column_identifier( column_identifier )

      check_column_index( row, column_index )

      row[ column_index ] = value
    end

    # Returns an array containing the values of a single row.
    #
    # _params_:
    #
    # +row_index+::                  int (0-based). see notes about the rows indexing.
    #
    def row( row_index )
      check_row_index( row_index )

      @data[ row_index ]
    end

    # Deletes a row.
    #
    # This operation won't modify the column width styles in any case.
    #
    # _params_:
    #
    # +row_index+::                  int (0-based). see notes about the rows indexing.
    #
    # _returns_ the deleted row
    #
    def delete_row( row_index )
      check_row_index( row_index )

      @data.slice!( row_index )
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
    def insert_row( row_index, row )
      check_row_index( row_index, :allow_append => true )

      @data.insert( row_index, row )
    end

    # This operation won't modify the column width styles in any case.
    #
    def append_row( row )
      insert_row( @data.size, row )
    end

    # Returns an array containing the values of a single column.
    #
    # WATCH OUT! This method doesn't have the range restrictions that axis indexes generally has, that is, it's possible to access a column outside the boundaries of the rows - it will return nil for each of those values.
    #
    # _params_:
    #
    # +column_indentifier+::         either an int (0-based) or the excel-format identifier (AA...).
    #                                when int, follow the same idea of the rows indexing (ruby semantics).
    #
    def column( column_identifier )
      column_index = decode_column_identifier( column_identifier )

      @data.map do | row |
        row[ column_index ]
      end
    end

    # Deletes a column.
    #
    # WATCH OUT! This method doesn't have the range restrictions that axis indexes generally has, that is, it's possible to delete a column outside the boundaries of the rows - it will return nil for each of those values.
    #
    # _params_:
    #
    # +column_indentifier+::         either an int (0-based) or the excel-format identifier (AA...).
    #                                when int, follow the same idea of the rows indexing (ruby semantics).
    #
    # _returns_ the deleted column
    #
    def delete_column( column_identifier )
      column_index = decode_column_identifier( column_identifier )

      @column_width_styles.slice!( column_index )

      @data.map do | row |
        row.slice!( column_index )
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
    def insert_column( column_identifier, column )
      raise "Inserting column size (#{ column.size }) different than existing columns size (#{ @data.size })" if @data.size > 0 && column.size != @data.size

      column_index = decode_column_identifier( column_identifier )

      @column_width_styles.insert( column_index, nil )

      if @data.size > 0
        @data.zip( column ).each do | row, value |
          row.insert( column_index, value )
        end
      else
        @data = column.map { | value | [ value ] }
      end

    end

    def append_column( column )
      column_index = @data.size > 0 ? @data.first.size : 0

      insert_column( column_index, column )
    end

    # _returns_ a matrix representation of the tables, with the values being separated by commas.
    #
    def to_s( options={} )
      pretty_print_rows( @data, options ) do | value |
        case value
        when BigDecimal
          value.to_s( 'F' )
        when Time
          # :to_s renders differently between 1.8.7 and 1.9.3.
          # 1.8.7's rendering is bizarrely inconsistent with the Date and DateTime ones.
          #
          value.strftime( '%Y-%m-%d %H:%M:%S %z' )
        when String, Date, Numeric
          value.to_s
        when true, false
          value.to_s
        when nil
          nil.inspect
        else
          raise "Invalid data type: #{ value }"
        end
      end
    end

    private

    # Check that row index points to an existing record, or, in case of :allow_append,
    # point to one unit above the last row.
    #
    # _options_:
    #
    # +allow_append+::      Allow pointing to one unit above the last row.
    #
    def check_row_index( row_index, options={} )
      allow_append = options [ :allow_append ]

      positive_limit = allow_append ? @data.size : @data.size - 1

      raise "Invalid row index (#{ row_index }) - allowed 0 to #{ positive_limit }" if row_index < 0 || row_index > positive_limit
    end

    def check_column_index( row, column_index )
      raise "Invalid column index (#{ column_index }) for the given row - allowed 0 to #{ row.size - 1 }" if column_index >= row.size
    end

    # Accepts either an integer, or a MoFoBase26BisexNumber.
    #
    # Raises an error for invalid identifiers/indexes.
    #
    # _returns_ a 0-based decimal number.
    #
    def decode_column_identifier( column_identifier )
      if column_identifier.is_a?( Fixnum )
        raise "Negative column indexes not allowed: #{ column_identifier }" if column_identifier < 0

        column_identifier
      else
        letters       = column_identifier.upcase.chars.to_a
        upcase_a_ord  = 65

        raise "Invalid letter for in column identifier (allowed 'a/A' to 'z/Z')" if letters.any? { | letter | letter < 'A' || letter > 'Z' }

        base_10_value = letters.inject( 0 ) do | sum, letter |
          letter_ord = letter.unpack( 'C' ).first
          sum * 26 + ( letter_ord - upcase_a_ord + 1 )
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
