#!/usr/bin/env ruby

require File.expand_path('../../lib/spreadbase', __FILE__)
require File.expand_path('../utils_helpers',     __FILE__)

include UtilsHelpers

def test_recoding_file(file_path)
  destination_file_path = file_path.sub(/\.ods$/, '.2.ods')

  document = SpreadBase::Document.new(file_path)
  document.document_path = destination_file_path
  document.save(:prettify => true)

  open_office_document(destination_file_path)
end

if __FILE__ == $PROGRAM_NAME
  file_path = ARGV[ 0 ] || raise("Usage: test_recoding_file.rb <file>")

  test_recoding_file(file_path)
end
