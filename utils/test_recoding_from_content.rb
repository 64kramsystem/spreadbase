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

require File.expand_path( '../../lib/spreadbase', __FILE__ )
require File.expand_path( '../utils_helpers',     __FILE__ )

include UtilsHelpers

def test_recoding_from_content( file_path )
  content_xml_data = IO.read( file_path )
  document         = SpreadBase::Codecs::OpenDocument12.new.decode_content_xml( content_xml_data )

  with_tempfile do | temp_file |
    document.document_path = temp_file.path
    document.save( :prettify => true )

    `openoffice.org3 #{ temp_file.path }`
  end
end

if __FILE__ == $0
  file_path = ARGV[ 0 ] || raise( "Usage: test_recoding_from_content.rb <file>" )

  test_recoding_from_content( file_path )
end
