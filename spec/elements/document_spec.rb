require_relative '../../lib/spreadbase'
require_relative '../spec_helpers'

include SpecHelpers

describe SpreadBase::Document do

  before :each do
    @sample_document = SpreadBase::Document.new
    @sample_document.tables = [
      SpreadBase::Table.new(
        'abc', [
          [ 1,      1.1,        T_BIGDECIMAL ],
          [ T_DATE, T_DATETIME, T_TIME       ],
          [ true,   'a',        nil          ]
        ]
      )
    ]
  end

  # :-D
  #
  it "should initialize out of thin air" do
    document = SpreadBase::Document.new

    expect(document.document_path).to be(nil)

    expect(document.tables).to be_empty
  end

  # A lazy use of stubs
  #
  it "should initialize from a file" do
    codec = stub_initializer(SpreadBase::Codecs::OpenDocument12)

    expect(File).to receive(:'exists?').with('/pizza/margerita.txt').and_return(true)
    expect(IO).to receive(:read).with('/pizza/margerita.txt').and_return('abc')
    expect(codec).to receive(:decode_archive).with('abc', {}).and_return(@sample_document)

    document = SpreadBase::Document.new('/pizza/margerita.txt')

    assert_size(document.tables, 1) do | table |
      expect(table.name).to eq('abc')
      expect(table.data.size).to eq(3)
    end
  end

  it "should initialize with a non-existing file" do
    codec = stub_initializer(SpreadBase::Codecs::OpenDocument12)

    document = SpreadBase::Document.new('/pizza/margerita.txt')

    assert_size(document.tables, 0)
  end

  it "should save to a file" do
    codec = stub_initializer(SpreadBase::Codecs::OpenDocument12)

    document = SpreadBase::Document.new
    document.tables << SpreadBase::Table.new('Ya-ha!')
    document.document_path = '/tmp/abc.ods'

    expect(codec).to receive(:encode_to_archive).with(document, prettify: 'abc').and_return('sob!')
    expect(File).to receive(:open).with('/tmp/abc.ods', 'wb')

    document.save(prettify: 'abc')
  end

  it "should raise an error when trying to save without a filename" do
    document = SpreadBase::Document.new
    document.tables << SpreadBase::Table.new('Ya-ha!')

    expect { document.save }.to raise_error(RuntimeError, "Document path not specified")
  end

  it "should raise an error when trying to save without tables" do
    document = SpreadBase::Document.new
    document.document_path = 'abc.ods'

    expect { document.save }.to raise_error(RuntimeError, "At least one table must be present")
  end

  it "should return the data as string (:to_s)" do
    expected_string = "\
abc:

  +------------+---------------------------+---------------------------+
  | 1          | 1.1                       | 1.33                      |
  | 2012-04-10 | 2012-04-11 23:33:42 +0000 | 2012-04-11 23:33:42 +0200 |
  | true       | a                         | NIL                       |
  +------------+---------------------------+---------------------------+

"

    expect(@sample_document.to_s).to eq(expected_string)
  end

  it "should return the data as string, with headers (:to_s)" do
    expected_string = "\
abc:

  +------------+---------------------------+---------------------------+
  | 1          | 1.1                       | 1.33                      |
  +------------+---------------------------+---------------------------+
  | 2012-04-10 | 2012-04-11 23:33:42 +0000 | 2012-04-11 23:33:42 +0200 |
  | true       | a                         | NIL                       |
  +------------+---------------------------+---------------------------+

"

    expect(@sample_document.to_s(with_headers: true)).to eq(expected_string)
  end

end
