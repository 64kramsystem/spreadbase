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

require 'date'
require 'bigdecimal'

module SpreadBase # :nodoc:

  module Codecs # :nodoc:

    module OpenDocument12Modules # :nodoc:

      # Module containing the decoding routines of the OpenDocument12 format.
      #
      module Decoding

        private

        # Returns a Document instance.
        #
        def decode_document_node( root_node, options={} )
          document = Document.new

          style_nodes = root_node.elements.to_a( '//office:document-content/office:automatic-styles/style:style' )
          table_nodes = root_node.elements.to_a( '//office:document-content/office:body/office:spreadsheet/table:table' )

          document.column_width_styles = decode_column_width_styles( style_nodes )

          document.tables = table_nodes.map { | node | decode_table_node( node, options ) }

          document
        end

        # Currently it has only the purpose of decoding the column widths (for this reason it has a different naming convention).
        #
        def decode_column_width_styles( style_nodes )
          style_nodes.inject( {} ) do | column_width_styles, style_node |
            column_node = style_node.elements[ 'style:table-column-properties' ]

            if column_node
              column_width = column_node.attributes[ 'style:column-width' ]

              if column_width
                style_name = style_node.attributes[ 'style:name' ]

                column_width_styles[ style_name] = column_width
              end
            end

            column_width_styles
          end
        end

        def decode_table_node( table_node, options )
          table = Table.new( table_node.attributes[ 'table:name' ] )

          column_nodes = table_node.elements.to_a( 'table:table-column' )
          row_nodes    = table_node.elements.to_a( 'table:table-row' )

          # A single column/row can represent multiple columns (table:number-(columns|rows)-repeated)
          #
          table.column_width_styles = column_nodes.inject( [] ) { | current_styles, node | current_styles + decode_column_width_style( node ) }
          table.data                = row_nodes.inject( [] ) { | current_rows, node | current_rows + decode_row_node( node, options ) }

          table
        end

        def decode_column_width_style( column_node )
          repeats    = column_node.attributes[ 'table:number-columns-repeated' ] || '1'
          style_name = column_node.attributes[ 'table:style-name' ]

          [ style_name ] * repeats.to_i
        end

        def decode_row_node( row_node, options )
          repeats    = row_node.attributes[ 'table:number-rows-repeated' ] || '1'
          cell_nodes = row_node.elements.to_a( 'table:table-cell' )

          # Watch out the :flatten; a single cell can represent multiple cells (table:number-columns-repeated)
          #
          values = cell_nodes.map { | node | decode_cell_node( node, options ) }.flatten

          [ values ] * repeats.to_i
        end

        def decode_cell_node( cell_node, options )
          floats_as_bigdecimal = options[ :floats_as_bigdecimal ]

          value_type = cell_node.attributes[ 'office:value-type' ]

          value = \
            case value_type
            when 'string'
              value_node = cell_node.elements[ 'text:p' ]

              value_node.text
            when 'date'
              date_string = cell_node.attributes[ 'office:date-value' ]

              if date_string =~ /T/
                DateTime.strptime( date_string, '%Y-%m-%dT%H:%M:%S' )
              else
                Date.strptime( date_string, '%Y-%m-%d' )
              end
            when 'float', 'percentage'
              float_string = cell_node.attributes[ 'office:value' ]

              if float_string.include?( '.' )
                if floats_as_bigdecimal
                  BigDecimal.new( float_string )
                else
                  float_string.to_f
                end
              else
                float_string.to_i
              end
            when 'boolean'
              boolean_string = cell_node.attributes[ 'office:boolean-value' ]

              case boolean_string
              when 'true'
                true
              when 'false'
                false
              else
                raise "Invalid boolean value: #{ boolean_string }"
              end
            when nil
              nil
            else
              raise "Unrecognized value type found in a cell: #{ value_type }"
            end

          repeats = cell_node.attributes[ 'table:number-columns-repeated' ] || '1'

          [ value ] * repeats.to_i
        end

      end

    end

  end

end
