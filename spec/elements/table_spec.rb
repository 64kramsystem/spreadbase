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

require File.expand_path( '../../../lib/spreadbase', __FILE__ )
require File.expand_path( '../../spec_helpers',      __FILE__ )

include SpecHelpers

describe SpreadBase::Table do

  before :each do
    @sample_table = SpreadBase::Table.new(
      'abc', [
        [ 1,      1.1,        T_BIGDECIMAL ],
        [ T_DATE, T_DATETIME, T_TIME       ],
        [ true,   'a',        nil          ]
      ]
    )
  end

  # The full test for checking the row index is here; all the other tests assume that
  # this routine is called, by checking against the index (-1).
  #
  it "should check the row index" do
    lambda { @sample_table.row( 4 ) }.should raise_error( RuntimeError, "Invalid row index (4) - allowed 0 to 2" )

    # called with :allow_append
    lambda { @sample_table.insert_row( -1, [] ) }.should raise_error( RuntimeError, "Invalid row index (-1) - allowed 0 to 3" )
    lambda { @sample_table.insert_row( 40, [] ) }.should raise_error( RuntimeError, "Invalid row index (40) - allowed 0 to 3" )
  end

  it "should initialize with data" do
    expected_data = [
      [ 1,      1.1,        T_BIGDECIMAL ],
      [ T_DATE, T_DATETIME, T_TIME       ],
      [ true,   'a',        nil          ]
    ]

    @sample_table.data.should == expected_data
  end

  it "should raise an error when the initialization requirements are not met" do
    lambda { SpreadBase::Table.new( nil ) }.should raise_error( "Table name required" )
    lambda { SpreadBase::Table.new( ''  ) }.should raise_error( "Table name required" )

    # This is acceptable
    #
    SpreadBase::Table.new( ' ' )
  end

  it "should access a cell" do
    @sample_table[ 'a', 0 ].should == 1
    @sample_table[ 1,   0 ].should == 1.1
    @sample_table[ 2,   0 ].should == T_BIGDECIMAL
    @sample_table[ 0,   1 ].should == T_DATE
    @sample_table[ 'B', 1 ].should == T_DATETIME
    @sample_table[ 2,   1 ].should == T_TIME
    @sample_table[ 0,   2 ].should == true
    @sample_table[ 1,   2 ].should == 'a'
    @sample_table[ 2,   2 ].should == nil

    lambda { @sample_table[ -1, 0 ] }.should raise_error( RuntimeError, "Negative column indexes not allowed: -1" )
    lambda { @sample_table[ 0, -1 ] }.should raise_error( RuntimeError, "Invalid row index (-1) - allowed 0 to 2" )
    lambda { @sample_table[ 3, 0  ] }.should raise_error( RuntimeError, "Invalid column index (3) for the given row - allowed 0 to 2" )
  end

  it "should set a cell value" do
    @sample_table[ 0,   0 ] = 10
    @sample_table[ 'B', 1 ] = T_TIME

    @sample_table.data.should == [
      [ 10,     1.1,        T_BIGDECIMAL ],
      [ T_DATE, T_TIME,     T_TIME       ],
      [ true,   'a',        nil          ],
    ]

    lambda { @sample_table[ 0, -1 ] = 33 }.should raise_error( RuntimeError, "Invalid row index (-1) - allowed 0 to 2" )
    lambda { @sample_table[ 3, 0  ] = 44 }.should raise_error( RuntimeError, "Invalid column index (3) for the given row - allowed 0 to 2" )
  end

  it "should access a row" do
    @sample_table.row( 0 ).should == [ 1,      1.1,        T_BIGDECIMAL ]
    @sample_table.row( 1 ).should == [ T_DATE, T_DATETIME, T_TIME       ]

    lambda { @sample_table.row( -1 ) }.should raise_error( RuntimeError, "Invalid row index (-1) - allowed 0 to 2" )
  end

  it "should delete a row" do
    @sample_table.delete_row( 1 ).should == [ T_DATE, T_DATETIME, T_TIME ]

    @sample_table.data.should == [
      [ 1,      1.1,        T_BIGDECIMAL ],
      [ true,   'a',        nil          ],
    ]

    lambda { @sample_table.delete_row( -1 ) }.should raise_error( RuntimeError, "Invalid row index (-1) - allowed 0 to 1" )
  end

  it "should insert a row" do
    @sample_table.insert_row( 1, [ 4, 5, 6 ] )

    @sample_table.data.should == [
      [ 1,      1.1,        T_BIGDECIMAL ],
      [ 4,      5,          6            ],
      [ T_DATE, T_DATETIME, T_TIME       ],
      [ true,   'a',        nil          ],
    ]

    # illegal row index tested in separate UT
  end

  it "should insert a row without error if there is no data" do
    @sample_table.data = []

    @sample_table.insert_row( 0, [ 4, 5 ] )

    @sample_table.data.size.should == 1
  end

  it "should append a row" do
    @sample_table.append_row( [ 4, 5, 6 ] )

    @sample_table.data.should == [
      [ 1,      1.1,        T_BIGDECIMAL ],
      [ T_DATE, T_DATETIME, T_TIME       ],
      [ true,   'a',        nil          ],
      [ 4,      5,          6            ],
    ]
  end

  it "should access a column" do
    @sample_table.column( 0 ).should == [ 1,   T_DATE,     true ]
    @sample_table.column( 1 ).should == [ 1.1, T_DATETIME, 'a'  ]

    @sample_table.column( 3 ).should == [ nil, nil, nil ]
  end

  it "should delete a column" do
    @sample_table.column_width_styles = [ 'abc', nil, 'cde' ]

    @sample_table.delete_column( 0 ).should == [ 1, T_DATE, true ]

    @sample_table.column_width_styles.should == [ nil, 'cde' ]

    @sample_table.delete_column( 3 ).should == [ nil, nil, nil ]

    @sample_table.column_width_styles.should == [ nil, 'cde' ]

    @sample_table.data.should == [
      [ 1.1,        T_BIGDECIMAL ],
      [ T_DATETIME, T_TIME       ],
      [ 'a',        nil          ]
    ]
  end

  it "should insert a column" do
    # Setup/fill table

    @sample_table.column_width_styles = [ 'abc', nil, 'cde' ]

    @sample_table.insert_column( 1, [ 34, 'abc', nil ] )

    @sample_table.data.should == [
      [ 1,      34,    1.1,        T_BIGDECIMAL ],
      [ T_DATE, 'abc', T_DATETIME, T_TIME       ],
      [ true,   nil,   'a',        nil          ],
    ]

    @sample_table.column_width_styles = [ 'abc', nil, nil, 'cde' ]

    # Empty table

    table = SpreadBase::Table.new( 'abc' )

    table.insert_column( 0, [ 34, 'abc', 1 ] )

    table.data.should == [
      [ 34,   ],
      [ 'abc' ],
      [ 1     ],
    ]

    @sample_table.column_width_styles = [ nil ]
  end

  it "should not insert a column if the size is not correct" do
    lambda { @sample_table.insert_column( 1, [ 34, 'abc' ] ) }.should raise_error( RuntimeError, "Inserting column size (2) different than existing columns size (3)" )

    @sample_table.data.first.size.should == 3
  end

  it "should insert a column outside the row boundaries" do
    @sample_table.insert_column( 5, [ 34, 'abc', nil ] )

    @sample_table.data.should == [
      [ 1,      1.1,        T_BIGDECIMAL, nil, nil, 34    ],
      [ T_DATE, T_DATETIME, T_TIME,       nil, nil, 'abc' ],
      [ true,   'a',        nil,          nil, nil, nil   ],
    ]
  end

  it "should append a column" do
    table = SpreadBase::Table.new( 'abc' )

    table.append_column( [ 34, 'abc', 1 ] )

    table.data.should == [
      [ 34,   ],
      [ 'abc' ],
      [ 1     ],
    ]

    table.append_column( [ 'cute', 'little', 'spielerin' ] )

    table.data.should == [
      [ 34,    'cute'      ],
      [ 'abc', 'little'    ],
      [ 1,     'spielerin' ],
    ]
  end

  it "return the data as string (:to_s)" #

  it "return the data as string, with headers (:to_s)" #

  it "should handle the column widths?"

end
