#!/usr/bin/env ruby

require File.expand_path('../utils_helpers', File.realpath(__FILE__))

include UtilsHelpers

def test_ods_folder(folder_path)
  with_tempfile do | temp_file |
    relative_compress_to_zip(folder_path, zip_filename: temp_file.path)

    open_office_document(temp_file.path)
  end
end

# Not sure if 'folder' is an accepted name in the linux world.
#
if __FILE__ == $PROGRAM_NAME
  folder_path = ARGV[0] || raise("Usage: test_ods_folder.rb <folder>")

  test_ods_folder(folder_path)
end
