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

require 'rexml/document'

def decode_cmdline_arguments
  if ( ARGV & [ '-h', '--help' ] ).any?
    puts 'Usage: prettify_xml_files.rb <file>[ <file>...]',
         '',
         'Formats (overwriting) the files passed.'
    exit
  else
    ARGV.clone
  end
end

def prettify_xml_string( source_xml_content )
  output_xml_buffer = ''

  root = REXML::Document.new( source_xml_content )

  xml_formatter = REXML::Formatters::Pretty.new
  xml_formatter.compact = true
  xml_formatter.write( root, output_xml_buffer )

  output_xml_buffer
end

def prettify_xml_files( filenames )
  filenames.each do | filename |
    puts "Prettifying #{ filename }..."

    source_xml_content = IO.read( filename )
    output_xml_content = prettify_xml_string( source_xml_content )

    IO.write( filename, output_xml_content )
  end

  nil
end

if __FILE__ == $0
  filenames = decode_cmdline_arguments

  prettify_xml_files( filenames )
end
