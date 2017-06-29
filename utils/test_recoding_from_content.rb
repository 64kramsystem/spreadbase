#!/usr/bin/env ruby

require_relative '../lib/spreadbase'
require_relative 'utils_helpers'

include UtilsHelpers

def test_recoding_from_content(file_path)
  content_xml_data = IO.read(file_path)
  document         = SpreadBase::Codecs::OpenDocument12.new.decode_content_xml(content_xml_data)

  with_tempfile do | temp_file |
    document.document_path = temp_file.path
    document.save(prettify: true)

    open_office_document(temp_file.path)
  end
end

if __FILE__ == $PROGRAM_NAME
  file_path = ARGV[0] || raise("Usage: test_recoding_from_content.rb <file>")

  test_recoding_from_content(file_path)
end
