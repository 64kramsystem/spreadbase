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

def pretty_print( file_path, output=$stdout )
  xml_str = IO.read( file_path )

  root = REXML::Document.new( xml_str )

  xml_formatter = REXML::Formatters::Pretty.new
  xml_formatter.compact = true
  xml_formatter.write( root, output )

  nil
end

def prettify_file( file_path )
  File.open( file_path, 'r+' ) do | file |
    pretty_print( file_path, file )
  end
end

if __FILE__ == $0
  file_path = ARGV[ 0 ] || raise( "Usage: prettify_file.rb <file>" )

  prettify_file( file_path )
end
