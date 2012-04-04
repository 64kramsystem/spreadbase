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

require 'tempfile'
require 'zipruby'

module UtilsHelpers

  # The file is closed before being passed to the block; even if overwritten, it's deleted when
  # the object is garbage-collected.
  #
  # options:
  #   :content        [nil]
  #   :name_prefix    [spreadbase_testing]
  #
  def with_tempfile( options={}, &block )
    content     = options[ :content     ]
    name_prefix = options[ :name_prefix ] || 'spreadbase_testing'

    temp_file = Tempfile.new( name_prefix )

    temp_file << content if content

    temp_file.close

    yield( temp_file )

    temp_file
  end

  # Create an archive, whose entries' path is relative to the path passed.
  #
  def relative_compress_to_zip( folder_path, options={} )
    absolute_path = File.expand_path( folder_path ) + '/'
    zip_filename  = options[ :zip_filename ] || File.expand_path( folder_path ) + '.zip'

    absolute_files = Dir.glob( absolute_path + '**/*' )

    Zip::Archive.open( zip_filename, Zip::CREATE ) do | archive |
      absolute_files.each do | absolute_file |
        # Lovely ZipRuby
        #
        next if File.directory?( absolute_file )

        relative_file = absolute_file.sub( absolute_path, '' )

        archive.add_file( relative_file, absolute_file )
      end
    end
  end

end
