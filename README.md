[![CI](https://github.com/saveriomiroddi/spreadbase/actions/workflows/ci.yml/badge.svg)](https://github.com/saveriomiroddi/spreadbase/actions/workflows/ci.yml)

SpreadBase!!
============

... because Excel IS a database.

Status
------

The library itself is stable, and can be regularly used.

I plan to add features on request, but if nobody asks for them, I will update the project very infrequently.

What is SpreadBase©?
--------------------

SpreadBase© is a set of APIs for programmatically accessing spreadsheets (currently, only OpenDocument 1.2).

Usage
-----

Install/require the gem:

    gem install spreadbase

    require 'spreadbase'

Create/open a document:

    document = SpreadBase::Document.new( "Today's menu.ods" )

Add a table:

    document.tables << SpreadBase::Table.new(
      'Transistors', [
        [ 'Roasted 6502',                                 38.911 ],
        [ '65000 with side dishes of Copper and Blitter', 512.0  ],
      ]
    )

Modify an existing table; can be done also directly on the array:

    table = document.tables.first

    table.insert_row( 0, [ 'Dish',                    'Price' ] )
    table.insert_row( 2, [ '8080, with an 8-bit bus', 8       ] )

    table.insert_column( 2, [ 'Availability', Date.today, Time.now + 42, 'Never!!' ] )

Add another (empty) table:

    table_2 = SpreadBase::Table.new( 'Loud and annoying customers' )

    document.tables << table_2

Append a column:

    table_2.append_column( [ 'Name' ] )

Append a row:

    table_2.append_row( [ 'Fabrizio F.' ] )

Read a column, or a range of columns:

    table.column( 0 )

    # [ 'Dish', 'Roasted 6502', '8080, with an 8-bit bus', '65000 with side dishes of Copper and Blitter' ]

    table.column( 0 .. 1 )

    # [ [ 'Dish',  'Roasted 6502', '8080, with an 8-bit bus', '65000 with side dishes of Copper and Blitter' ],
    #   [ 'Price', 38.911,         8,                         512.0                                          ] ]

Read a row, or a range of rows:

    table.row( 1 )

    # [ 'Roasted 6502', 38.911 ]

    table.row( 1 .. 2 )

    # [ [ 'Roasted 6502', 38.911 ], [ '8080, with an 8-bit bus', 8 ] ]

Read a cell:

    price_8080 = document.tables[ 0 ][ 1, 2 ]

When a cell value is read from an existing file, the data type is directly converted to the closest ruby one.

Write to a cell:

    document.tables[ 0 ][ 1, 2 ] = price_8080 + 0.080

Print a table:

    puts document.tables[ 0 ].to_s( :with_headers => true )

    +----------------------------------------------+--------+---------------------------+
    | Dish                                         | Price  | Availability              |
    +----------------------------------------------+--------+---------------------------+
    | Roasted 6502                                 | 38.911 | 2012-04-21                |
    | 8080, with an 8-bit bus                      | 8.08   | 2012-04-21 11:45:08 +0200 |
    | 65000 with side dishes of Copper and Blitter | 512.0  | Never!!                   |
    +----------------------------------------------+--------+---------------------------+

Print a document:

    puts document.to_s( :with_headers => true )

    Transistors:

      +----------------------------------------------+--------+---------------------------+
      | Dish                                         | Price  | Availability              |
      +----------------------------------------------+--------+---------------------------+
      | Roasted 6502                                 | 38.911 | 2012-04-21                |
      | 8080, with an 8-bit bus                      | 8.08   | 2012-04-21 11:45:08 +0200 |
      | 65000 with side dishes of Copper and Blitter | 512.0  | Never!!                   |
      +----------------------------------------------+--------+---------------------------+

    Loud and annoying customers:

      +-------------+
      | Name        |
      +-------------+
      | Fabrizio F. |
      +-------------+

Save the document:

    document.save

Enjoy many other APIs.

Notes
-----

- Numbers are decoded to Fixnum or Float, depending on the existence of the fractional part.
  Alternatively, numbers with a fractional part can be decoded as Bigdecimal, using the option:

  `SpreadBase::Document.new( "Random numbers für alle!.ods", floats_as_bigdecimal: true )`

- The gem is tested on all the supported Ruby versions (see [Build](https://github.com/saveriomiroddi/spreadbase/actions/workflows/ci.yml)), and used mainly on Linux.
- The column widths are retained (decoding/encoding), but at the current version, they're not [officially] accessible via any API.

Currently unsupported features
------------------------------

- Styles; Date and and [Date]Times are formatted as, respectively, '%Y-%m-%d' and '%Y-%m-%d %H:%M:%S %z'
- Percentage data type - they're handled using their float value (e.g. 50% = 0.5)

Roadmap/Todo
------------

https://github.com/saveriomiroddi/spreadbase/wiki/Todo-%28roadmap%29
