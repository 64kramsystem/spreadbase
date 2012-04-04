#!/usr/bin/env ruby
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

require 'rubygems'
require 'sqlite3'
require 'spreadbase'

def decode_cmdline_params
  if [ '-h', '--help' ].include?( ARGV[ 0 ] ) || ARGV.size == 0 || ARGV.size > 1
    puts "Usage: convert_sqlite_to_ods.rb <filename>"

    exit
  else
    ARGV[ 0 ]
  end
end

def generate_destination_filename( source_filename )
  "#{ source_filename }.ods"
end

def with_database( filename, &block )
  @db = SQLite3::Database.new( filename )
  @db.type_translation = true
  @db.extend( SQLite3::Pragmas )

  yield
ensure
  @db.close if @db
end

def with_spreadsheet( filename )
  @spreadsheet = SpreadBase::Document.new( filename )

  yield
ensure
  @spreadsheet.save if @spreadsheet
end

def find_tables
  sql = "
    SELECT name
    FROM sqlite_master
    WHERE type = 'table'
  "

  @db.execute( sql ).map( &:first ) - [ 'sqlite_sequence' ]
end

# Sample:
#
#     {
#       "cid"        => 3,
#       "name"       => "title_en",
#       "type"       => "TEXT",
#       "notnull"    => 0,
#       "dflt_value" => nil,
#       "pk"         => 0
#     },
#
def find_table_columns( table )
  raw_data = @db.table_info( table )

  raw_data.map { | column_data | column_data[ 'name' ] }
end

def create_destination_table( table_name, columns )
  table = SpreadBase::Table.new( table_name )

  @spreadsheet.tables << table

  table
end

def select_all_rows( table )
  sql = "SELECT * FROM #{ table }"

  @db.execute( sql )
end

def insert_row_into_destination( destination_table, row )
  # row = row.map do | value |
  #   if value.is_a?( String )
  #     begin
  #       value.encode( 'UTF-8' )

  #       value
  #     rescue
  #       puts "#{ value.inspect } => #{ $! }"

  #       value.force_encoding( 'UTF-8' )
  #     end
  #   else
  #     value
  #   end
  # end

  # holy crap it's really easy to work with SB. kudos to myself.
  #
  destination_table.append_row( row )
end

# +options+:
# +insert_headers+::          (true) insert the column names as headers
#
def convert_sqlite_to_ods( source_filename, options={} )
  insert_headers = ! options.has_key?( :insert_headers ) || options[ :insert_headers ]

  destination_filename = generate_destination_filename( source_filename )

  with_database( source_filename ) do
    with_spreadsheet( destination_filename ) do
      tables = find_tables

      tables.each do | table |
        columns = find_table_columns( table )

        destination_table = create_destination_table( table, columns )

        insert_row_into_destination( destination_table, columns ) if insert_headers

        value_rows = select_all_rows( table )

        value_rows.each do | row |
          insert_row_into_destination( destination_table, row )
        end
      end
    end
  end
end

if __FILE__ == $0
  filename = decode_cmdline_params

  convert_sqlite_to_ods( filename )
end
