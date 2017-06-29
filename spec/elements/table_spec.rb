require_relative '../../lib/spreadbase'
require_relative '../spec_helpers'

include SpecHelpers

include SpreadBase

describe SpreadBase::Table do

  before :each do
    @sample_table = SpreadBase::Table.new(
      'abc', [
        [ 1,      1.1,             T_BIGDECIMAL ],
        [ T_DATE, T_DATETIME,      T_TIME       ],
        [ true,   Cell.new('a'), nil          ]
      ]
    )
  end

  # The full test for checking the row index is here; all the other tests assume that
  # this routine is called, by checking against the index (-1).
  #
  it "should check the row index" do
    expect { @sample_table.row(4) }.to raise_error(RuntimeError, "Invalid row index (4) - allowed 0 to 2")

    # called with :allow_append
    expect { @sample_table.insert_row(-1, []) }.to raise_error(RuntimeError, "Invalid row index (-1) - allowed 0 to 3")
    expect { @sample_table.insert_row(40, []) }.to raise_error(RuntimeError, "Invalid row index (40) - allowed 0 to 3")
  end

  it "should initialize with data, and return the data" do
    expected_data = [
      [ 1,      1.1,        T_BIGDECIMAL ],
      [ T_DATE, T_DATETIME, T_TIME       ],
      [ true,   'a',        nil          ]
    ]

    expect(@sample_table.data).to eq(expected_data)
  end

  it "return the data in cell format" do
    expected_data = [
      [ Cell.new(1),      Cell.new(1.1),        Cell.new(T_BIGDECIMAL) ],
      [ Cell.new(T_DATE), Cell.new(T_DATETIME), Cell.new(T_TIME)       ],
      [ Cell.new(true),   Cell.new('a'),        Cell.new(nil)          ]
    ]

    expect(@sample_table.data(as_cell: true)).to eq(expected_data)
  end

  it "should raise an error when the initialization requirements are not met" do
    expect { SpreadBase::Table.new(nil) }.to raise_error("Table name required")
    expect { SpreadBase::Table.new('') }.to raise_error("Table name required")

    # This is acceptable
    #
    SpreadBase::Table.new(' ')
  end

  it "should access a cell" do
    expect(@sample_table[ 'a', 0 ]).to eq(1)
    expect(@sample_table[ 1,   0 ]).to eq(1.1)
    expect(@sample_table[ 2,   0 ]).to eq(T_BIGDECIMAL)
    expect(@sample_table[ 0,   1 ]).to eq(T_DATE)
    expect(@sample_table[ 'B', 1 ]).to eq(T_DATETIME)
    expect(@sample_table[ 2,   1 ]).to eq(T_TIME)
    expect(@sample_table[ 0,   2 ]).to eq(true)
    expect(@sample_table[ 1,   2 ]).to eq('a')
    expect(@sample_table[ 2,   2 ]).to eq(nil)

    expect(@sample_table[ 1, 2, as_cell: true ]).to eq(Cell.new('a'))

    expect { @sample_table[ -1, 0 ] }.to raise_error(RuntimeError, "Negative column indexes not allowed: -1")
    expect { @sample_table[ 0, -1 ] }.to raise_error(RuntimeError, "Invalid row index (-1) - allowed 0 to 2")
    expect { @sample_table[ 3, 0  ] }.to raise_error(RuntimeError, "Invalid column index (3) for the given row - allowed 0 to 2")
  end

  it "should set a cell value" do
    @sample_table[ 0,   0 ] = 10
    @sample_table[ 'B', 1 ] = Cell.new(T_TIME)

    expect(@sample_table.data).to eq([
      [ 10,     1.1,        T_BIGDECIMAL ],
      [ T_DATE, T_TIME,     T_TIME       ],
      [ true,   'a',        nil          ],
    ])

    expect { @sample_table[ 0, -1 ] = 33 }.to raise_error(RuntimeError, "Invalid row index (-1) - allowed 0 to 2")
    expect { @sample_table[ 3, 0  ] = 44 }.to raise_error(RuntimeError, "Invalid column index (3) for the given row - allowed 0 to 2")
  end

  it "should access a row" do
    expect(@sample_table.row(0)).to eq([ 1, 1.1, T_BIGDECIMAL ])

    expect(@sample_table.row(1, as_cell: true)).to eq([ Cell.new(T_DATE), Cell.new(T_DATETIME), Cell.new(T_TIME) ])

    expect { @sample_table.row(-1) }.to raise_error(RuntimeError, "Invalid row index (-1) - allowed 0 to 2")
  end

  it "should access a set of rows by range" do
    expect(@sample_table.row(0..1)).to eq([
      [ 1,      1.1,        T_BIGDECIMAL ],
      [ T_DATE, T_DATETIME, T_TIME       ],
    ])

    expect { @sample_table.row(0..5) }.to raise_error(RuntimeError, "Invalid row index (5) - allowed 0 to 2")
  end

  it "should access a set of rows by range (as cell)" do
    expect(@sample_table.row(0..1, as_cell: true)).to eq([
      [ Cell.new(1),      Cell.new(1.1),        Cell.new(T_BIGDECIMAL) ],
      [ Cell.new(T_DATE), Cell.new(T_DATETIME), Cell.new(T_TIME)       ],
    ])

    expect { @sample_table.row(0..5) }.to raise_error(RuntimeError, "Invalid row index (5) - allowed 0 to 2")
  end

  it "should delete a row" do
    expect(@sample_table.delete_row(1)).to eq([ T_DATE, T_DATETIME, T_TIME ])

    expect(@sample_table.data).to eq([
      [ 1,      1.1,        T_BIGDECIMAL ],
      [ true,   'a',        nil          ],
    ])

    expect { @sample_table.delete_row(-1) }.to raise_error(RuntimeError, "Invalid row index (-1) - allowed 0 to 1")
  end

  it "should delete a set of rows by range" do
    expect(@sample_table.delete_row(0..1)).to eq([
      [ 1,      1.1,        T_BIGDECIMAL ],
      [ T_DATE, T_DATETIME, T_TIME       ],
    ])

    expect(@sample_table.data).to eq([
      [ true,   'a',        nil          ]
    ])

    expect { @sample_table.delete_row(0..5) }.to raise_error(RuntimeError, "Invalid row index (5) - allowed 0 to 0")
  end

  it "should insert a row" do
    @sample_table.insert_row(1, [ 4, Cell.new(5), 6 ])

    expect(@sample_table.data).to eq([
      [ 1,      1.1,        T_BIGDECIMAL ],
      [ 4,      5,          6            ],
      [ T_DATE, T_DATETIME, T_TIME       ],
      [ true,   'a',        nil          ],
    ])

    # illegal row index tested in separate UT
  end

  it "should insert a row without error if there is no data" do
    @sample_table.data = []

    @sample_table.insert_row(0, [ 4, 5 ])

    expect(@sample_table.data.size).to eq(1)
  end

  it "should append a row" do
    @sample_table.append_row([ 4, Cell.new(5), 6 ])

    expect(@sample_table.data).to eq([
      [ 1,      1.1,        T_BIGDECIMAL ],
      [ T_DATE, T_DATETIME, T_TIME       ],
      [ true,   'a',        nil          ],
      [ 4,      5,          6            ],
    ])
  end

  it "should access a column" do
    expect(@sample_table.column(0)).to eq([ 1,   T_DATE,     true ])

    expect(@sample_table.column(1, as_cell: true)).to eq([ Cell.new(1.1), Cell.new(T_DATETIME), Cell.new('a') ])

    expect(@sample_table.column(3)).to eq([ nil, nil, nil ])
  end

  it "should access a set of columns by range" do
    expect(@sample_table.column(0..1)).to eq([
      [ 1,   T_DATE,     true ],
      [ 1.1, T_DATETIME, 'a'  ],
    ])

    expect(@sample_table.column('C'..'D')).to eq([
      [ T_BIGDECIMAL, T_TIME, nil ],
      [ nil,          nil,    nil ],
    ])
  end

  it "should access a set of columns by range (as cell )" do
    expect(@sample_table.column(0..1, as_cell: true)).to eq([
      [ Cell.new(1),   Cell.new(T_DATE),     Cell.new(true) ],
      [ Cell.new(1.1), Cell.new(T_DATETIME), Cell.new('a')  ],
    ])
  end

  it "should delete a column" do
    @sample_table.column_width_styles = [ 'abc', nil, 'cde' ]

    expect(@sample_table.delete_column(0)).to eq([ 1, T_DATE, true ])

    expect(@sample_table.column_width_styles).to eq([ nil, 'cde' ])

    expect(@sample_table.delete_column(3)).to eq([ nil, nil, nil ])

    expect(@sample_table.column_width_styles).to eq([ nil, 'cde' ])

    expect(@sample_table.data).to eq([
      [ 1.1,        T_BIGDECIMAL ],
      [ T_DATETIME, T_TIME       ],
      [ 'a',        nil          ]
    ])
  end

  it "should delete a set of columns by range" do
    expect(@sample_table.delete_column(0..1)).to eq([
      [ 1,   T_DATE, true ],
      [ 1.1, T_DATETIME, 'a'  ],
    ])

    expect(@sample_table.data).to eq([
      [ T_BIGDECIMAL ],
      [ T_TIME       ],
      [ nil          ],
    ])
  end

  it "should insert a column" do
    # Setup/fill table

    @sample_table.column_width_styles = [ 'abc', nil, 'cde' ]

    @sample_table.insert_column(1, [ 34, 'abc', Cell.new(nil) ])

    expect(@sample_table.data).to eq([
      [ 1,      34,    1.1,        T_BIGDECIMAL ],
      [ T_DATE, 'abc', T_DATETIME, T_TIME       ],
      [ true,   nil,   'a',        nil          ],
    ])

    @sample_table.column_width_styles = [ 'abc', nil, nil, 'cde' ]

    # Empty table

    table = SpreadBase::Table.new('abc')

    table.insert_column(0, [ 34, 'abc', 1 ])

    expect(table.data).to eq([
      [ 34,   ],
      [ 'abc' ],
      [ 1     ],
    ])

    @sample_table.column_width_styles = [ nil ]
  end

  it "should not insert a column if the size is not correct" do
    expect { @sample_table.insert_column(1, [ 34, 'abc' ]) }.to raise_error(RuntimeError, "Inserting column size (2) different than existing columns size (3)")

    expect(@sample_table.data.first.size).to eq(3)
  end

  it "should insert a column outside the row boundaries" do
    @sample_table.insert_column(5, [ 34, 'abc', nil ])

    expect(@sample_table.data).to eq([
      [ 1,      1.1,        T_BIGDECIMAL, nil, nil, 34    ],
      [ T_DATE, T_DATETIME, T_TIME,       nil, nil, 'abc' ],
      [ true,   'a',        nil,          nil, nil, nil   ],
    ])
  end

  it "should append a column" do
    table = SpreadBase::Table.new('abc')

    table.append_column([ Cell.new(34), 'abc', 1 ])

    expect(table.data).to eq([
      [ 34,   ],
      [ 'abc' ],
      [ 1     ],
    ])

    table.append_column([ 'cute', 'little', 'spielerin' ])

    expect(table.data).to eq([
      [ 34,    'cute'      ],
      [ 'abc', 'little'    ],
      [ 1,     'spielerin' ],
    ])
  end

  it "return the data as string (:to_s)" do
    expected_string = "\
+------------+---------------------------+---------------------------+
| 1          | 1.1                       | 1.33                      |
| 2012-04-10 | 2012-04-11 23:33:42 +0000 | 2012-04-11 23:33:42 +0200 |
| true       | a                         | NIL                       |
+------------+---------------------------+---------------------------+
"
    expect(@sample_table.to_s).to eq(expected_string)
  end

  it "return the data as string, with headers (:to_s)" do
    expected_string = "\
+------------+---------------------------+---------------------------+
| 1          | 1.1                       | 1.33                      |
+------------+---------------------------+---------------------------+
| 2012-04-10 | 2012-04-11 23:33:42 +0000 | 2012-04-11 23:33:42 +0200 |
| true       | a                         | NIL                       |
+------------+---------------------------+---------------------------+
"

    expect(@sample_table.to_s(with_headers: true)).to eq(expected_string)

    @sample_table.data = []

    expect(@sample_table.to_s(with_headers: true)).to eq("")
  end

end
