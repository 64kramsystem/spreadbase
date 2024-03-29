require 'date'
require 'bigdecimal'

module SpreadBase # :nodoc:

  module Codecs # :nodoc:

    module OpenDocument12Modules # :nodoc:

      # Module containing the decoding routines of the OpenDocument12 format.
      #
      module Decoding

        include SpreadBase::Helpers

        private

        # Returns a Document instance.
        #
        def decode_document_node(root_node, **options)
          document = Document.new

          style_nodes = root_node.elements.to_a('//office:document-content/office:automatic-styles/style:style')
          table_nodes = root_node.elements.to_a('//office:document-content/office:body/office:spreadsheet/table:table')

          document.column_width_styles = decode_column_width_styles(style_nodes)

          document.tables = table_nodes.map { | node | decode_table_node(node, **options) }

          document
        end

        # Currently it has only the purpose of decoding the column widths (for this reason it has a different naming convention).
        #
        def decode_column_width_styles(style_nodes)
          style_nodes.inject({}) do | column_width_styles, style_node |
            column_node = style_node.elements['style:table-column-properties']

            if column_node
              column_width = column_node.attributes['style:column-width']

              if column_width
                style_name = style_node.attributes['style:name']

                column_width_styles[style_name] = column_width
              end
            end

            column_width_styles
          end
        end

        def decode_table_node(table_node, **options)
          table = Table.new(table_node.attributes['table:name'])

          column_nodes = table_node.elements.to_a('table:table-column')
          row_nodes    = table_node.elements.to_a('table:table-row')

          # A single column/row can represent multiple columns (table:number-(columns|rows)-repeated)
          #
          table.column_width_styles = column_nodes.inject([]) { | current_styles, node | current_styles + decode_column_width_style(node) }
          table.data                = decode_row_nodes(row_nodes, **options)

          table
        end

        def decode_column_width_style(column_node)
          repetitions = (column_node.attributes['table:number-columns-repeated'] || '1').to_i
          style_name  = column_node.attributes['table:style-name']

          # WATCH OUT! See module note
          #
          make_array_from_repetitions(style_name, repetitions)
        end

        def decode_row_nodes(row_nodes, **options)
          rows = []
          row_nodes.inject(0) do |size, node|
            row, repetitions = decode_row_node(node, **options)
            row.empty? || append_row(rows, size, row, repetitions)
            size + repetitions
          end
          rows
        end

        def decode_row_node(row_node, **options)
          repetitions = (row_node.attributes['table:number-rows-repeated'] || '1').to_i
          cell_nodes  = row_node.elements.to_a('table:table-cell')

          [decode_cell_nodes(cell_nodes, **options), repetitions]
        end

        def append_row(rows, size, row, repetitions)
          (size - rows.size).times { rows << [] }
          rows.concat(make_array_from_repetitions(row, repetitions))
        end

        def decode_cell_nodes(cell_nodes, **options)
          cells = []
          cell_nodes.inject(0) do |size, node|
            cell, repetitions = decode_cell_node(node, **options)
            cell.nil? || append_cell(cells, size, cell, repetitions)
            size + repetitions
          end
          cells
        end

        def decode_cell_node(cell_node, **options)
          [
            decode_cell_value(cell_node, **options),
            (cell_node.attributes['table:number-columns-repeated'] || '1').to_i
          ]
        end

        def append_cell(cells, size, cell, repetitions)
          cells[size - 1] = nil if size != cells.size
          cells.concat(make_array_from_repetitions(cell, repetitions))
        end

        def decode_cell_value(cell_node, **options)
          floats_as_bigdecimal = options[:floats_as_bigdecimal]

          value_type = cell_node.attributes['office:value-type']

          case value_type
          when 'string'
            cell_node
              .elements.collect('text:p', &:text)
              .join("\n")
          when 'date'
            date_string = cell_node.attributes['office:date-value']

            if date_string =~ /T/
              DateTime.strptime(date_string, '%Y-%m-%dT%H:%M:%S')
            else
              Date.strptime(date_string, '%Y-%m-%d')
            end
          when 'float', 'percentage'
            float_string = cell_node.attributes['office:value']

            if float_string.include?('.')
              if floats_as_bigdecimal
                BigDecimal(float_string)
              else
                float_string.to_f
              end
            else
              float_string.to_i
            end
          when 'boolean'
            boolean_string = cell_node.attributes['office:boolean-value']

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
        end

      end

    end

  end

end
