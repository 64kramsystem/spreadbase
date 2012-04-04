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

require 'date'
require 'bigdecimal'

module SpecHelpers

  T_DATE       = Date.new( 2012, 4, 10 )
  T_DATETIME   = DateTime.new( 2012, 4, 11, 23, 33, 42 )
  T_TIME       = Time.local( 2012, 4, 11, 23, 33, 42 )
  T_BIGDECIMAL = BigDecimal.new( '1.33' )

  # This method is cool beyond any argument about the imperfect name.
  #
  def assert_size( collection, expected_size )
    collection.size.should == expected_size

    yield( *collection ) if block_given?
  end

  def stub_initializer( klazz, *args )
    instance = klazz.new( *args )

    klazz.stub!( :new ).and_return( instance )

    instance
  end

end
