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

require 'rexml/document'
require 'date'
require 'bigdecimal'

module SpreadBase # :nodoc:

  module Codecs # :nodoc:

    module OpenDocument12Modules # :nodoc:

      # Module containing the encoding routines of the OpenDocument12 format.
      #
      module Encoding

        # Actually a document can be opened even without the office:body element, but we simplify the code
        # by assuming that at least this tree is present.
        #
        BASE_CONTENT_XML = %Q[\
<?xml version='1.0' encoding='UTF-8'?>
<office:document-content
    xmlns:office='urn:oasis:names:tc:opendocument:xmlns:office:1.0'
    xmlns:style='urn:oasis:names:tc:opendocument:xmlns:style:1.0'
    xmlns:table='urn:oasis:names:tc:opendocument:xmlns:table:1.0'
    xmlns:text='urn:oasis:names:tc:opendocument:xmlns:text:1.0'
    xmlns:fo='urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0'
    xmlns:number='urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0'
    xmlns:of='urn:oasis:names:tc:opendocument:xmlns:of:1.2'
    office:version='1.2'>
<office:automatic-styles>
  <number:date-style style:name='N37'>
    <number:month number:style='long'/>
    <number:text>/</number:text>
    <number:day number:style='long'/>
    <number:text>/</number:text>
    <number:year/>
  </number:date-style>
  <number:date-style style:name='N5050'>
    <number:month/>
    <number:text>/</number:text>
    <number:day/>
    <number:text>/</number:text>
    <number:year/>
    <number:text> </number:text>
    <number:hours number:style='long'/>
    <number:text>:</number:text>
    <number:minutes number:style='long'/>
    <number:text> </number:text>
    <number:am-pm/>
  </number:date-style>
  <style:style style:name='date' style:family='table-cell' style:data-style-name='N37'/>
  <style:style style:name='datetime' style:family='table-cell' style:data-style-name='N5050'/>
  <style:style style:name='boolean' style:family='table-cell' style:data-style-name='N99'/>
</office:automatic-styles>
<office:body>
  <office:spreadsheet/>
</office:body>
</office:document-content>] # :nodoc:

        private

        # Returns the XML root node
        #
        def encode_to_document_node( el_document )
          root_node        = REXML::Document.new( BASE_CONTENT_XML )
          spreadsheet_node = root_node.elements[ '//office:document-content/office:body/office:spreadsheet' ]
          styles_node      = root_node.elements[ '//office:document-content/office:automatic-styles'        ]

          el_document.column_width_styles.each do | style_name, column_width |
            encode_style( styles_node, style_name, column_width )
          end

          el_document.tables.each do | table |
            encode_table( table, spreadsheet_node )
          end

          root_node
        end

        # Currently only encodes column width styles
        #
        def encode_style( styles_node, style_name, column_width )
          style_node = styles_node.add_element( 'style:style', 'style:name' => style_name, 'style:family' => 'table-column' )

          style_node.add_element( 'style:table-column-properties', 'style:column-width' => column_width )
        end

        def encode_table( table, spreadsheet_node )
          table_node = spreadsheet_node.add_element( 'table:table' )

          table_node.attributes[ 'table:name' ] = table.name

          table.column_width_styles.each do | style_name |
            encode_column( table_node, style_name ) if style_name
          end

          # At least one column element is required
          #
          table_node.add_element( 'table:table-column' ) if table.column_width_styles.size == 0

          table.data( as_cell: true ).each do | row |
            encode_row( row, table_node )
          end
        end

        # Currently only encodes column width styles
        #
        def encode_column( table_node, style_name )
          table_node.add_element( 'table:table-column', 'table:style-name' => style_name )
        end

        def encode_row( row, table_node )
          row_node = table_node.add_element( 'table:table-row' )

          row.each do | cell |
            encode_cell( cell.value, row_node )
          end
        end

        def encode_cell( value, row_node )
          cell_node = row_node.add_element( 'table:table-cell' )

          # WATCH OUT!!! DateTime.new.is_a?( Date )!!!
          #
          case value
          when String
            cell_node.attributes[ 'office:value-type' ] = 'string'

            cell_value_node = cell_node.add_element( 'text:p' )

            cell_value_node.text = value.encode( 'UTF-8' )
          when Time, DateTime
            cell_node.attributes[ 'office:value-type' ] = 'date'
            cell_node.attributes[ 'table:style-name'  ] = 'datetime'

            encoded_value = value.strftime( '%Y-%m-%dT%H:%M:%S' )

            cell_node.attributes[ 'office:date-value' ] = encoded_value
          when Date
            cell_node.attributes[ 'office:value-type' ] = 'date'
            cell_node.attributes[ 'table:style-name'  ] = 'date'

            encoded_value = value.strftime( '%Y-%m-%d' )

            cell_node.attributes[ 'office:date-value' ] = encoded_value
          when BigDecimal
            cell_node.attributes[ 'office:value-type' ] = 'float'

            cell_node.attributes[ 'office:value' ] = value.to_s( 'F' )
          when Float, Fixnum
            cell_node.attributes[ 'office:value-type' ] = 'float'

            cell_node.attributes[ 'office:value' ] = value.to_s
          when true, false
            cell_node.attributes[ 'office:value-type' ] = 'boolean'
            cell_node.attributes[ 'table:style-name'  ] = 'boolean'

            cell_node.attributes[ 'office:boolean-value' ] = value.to_s
          when nil
            # do nothing
          else
            raise "Unrecognized value class: #{ value.class }"
          end
        end

      end

    end

  end

end
