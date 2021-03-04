require_relative '../../lib/spreadbase'
require_relative '../spec_helpers'

require 'date'
require 'bigdecimal'

include SpecHelpers

# See testing notes.
#
describe SpreadBase::Codecs::OpenDocument12 do

  before :each do
    table_1 = SpreadBase::Table.new(
      'abc', [
        [1,      1.1,        T_BIGDECIMAL],
        [T_DATE, T_DATETIME, T_TIME],
        [nil,    nil,        'a']
      ]
    )

    table_2 = SpreadBase::Table.new('cde')

    @sample_document = SpreadBase::Document.new

    @sample_document.tables << table_1 << table_2
  end

  # :encode/:decode
  #
  it "should encode and decode the sample document" do
    document_archive = SpreadBase::Codecs::OpenDocument12.new.encode_to_archive(@sample_document)

    document = SpreadBase::Codecs::OpenDocument12.new.decode_archive(document_archive, floats_as_bigdecimal: true)

    assert_size(document.tables, 2) do | table_1, table_2 |

      expect(table_1.name).to eq('abc')

      assert_size(table_1.data, 3) do | row_1, row_2, row_3 |

        assert_size(row_1, 3) do | value_1, value_2, value_3 |
          expect(value_1).to eq(1)
          expect(value_1).to be_a(Integer)
          expect(value_2).to eq(1.1)
          expect(value_2).to be_a(BigDecimal)
          expect(value_3).to eq(T_BIGDECIMAL)
          expect(value_3).to be_a(BigDecimal)
        end

        assert_size(row_2, 3) do | value_1, value_2, value_3 |
          expect(value_1).to eq(T_DATE)
          expect(value_2).to eq(T_DATETIME)
          expect(value_3).to eq(T_DATETIME)
        end

        assert_size(row_3, 3) do | value_1, value_2, value_3 |
          expect(value_1).to eq(nil)
          expect(value_2).to eq(nil)
          expect(value_3).to eq('a')
        end

      end

      expect(table_2.name).to eq('cde')

      assert_size(table_2.data, 0)
    end
  end

  # Not worth testing in detail; just ensure that the pref
  #
  it "should encode the document with makeup (:prettify) - SMOKE" do
    formatter = stub_initializer(REXML::Formatters::Pretty)

    expect(formatter).to receive(:write)

    SpreadBase::Codecs::OpenDocument12.new.encode_to_archive(@sample_document, prettify: true)
  end

  # Those methods are actually "utility" (read: testing) methods.
  #
  it "should encode/decode the content.xml - SMOKE" do
    content_xml = SpreadBase::Codecs::OpenDocument12.new.encode_to_content_xml(@sample_document)

    document = SpreadBase::Codecs::OpenDocument12.new.decode_content_xml(content_xml)

    assert_size(document.tables, 2)
  end

  # If values are not converted to UTF-8, some encodings cause an error to be
  # raised when assigning a value to a cell.
  #
  it "should convert to utf-8 before saving" do
    string = "à".encode('utf-16')

    @sample_document.tables[0][0,  0] = string

    # Doesn't encode correctly if the value is not converted
    #
    SpreadBase::Codecs::OpenDocument12.new.encode_to_content_xml(@sample_document)
  end

  it "should decode as BigDecimal" do
    content_xml = SpreadBase::Codecs::OpenDocument12.new.encode_to_content_xml(@sample_document)

    document = SpreadBase::Codecs::OpenDocument12.new.decode_content_xml(content_xml, floats_as_bigdecimal: true)

    value = document.tables[0][2, 0]

    expect(value).to be_a(BigDecimal)
    expect(value).to eq(T_BIGDECIMAL)
  end

  context "when cells at the end of the row are empty" do
    let(:document_archive) do
      document = SpreadBase::Document.new

      document.tables << SpreadBase::Table.new(
        'abc', [
          [nil],
          [nil, nil],
          [1  , nil],
          [nil, 1  , nil]
        ]
      )

      SpreadBase::Codecs::OpenDocument12.new.encode_to_archive(document)
    end

    it "should drop such cells" do
      document = SpreadBase::Codecs::OpenDocument12.new.decode_archive(document_archive)
      table = document.tables[0]

      assert_size(table.data, 4) do |row_1, row_2, row_3, row_4|
        assert_size(row_1, 0)

        assert_size(row_2, 0)

        assert_size(row_3, 1) do |value_1|
          expect(value_1).to eq(1)
        end

        assert_size(row_4, 2) do |value_1, value_2|
          expect(value_1).to be_nil
          expect(value_2).to eq(1)
        end
      end
    end
  end

  context "when cells of the last row are empty" do
    let(:document_archive) do
      document = SpreadBase::Document.new

      document.tables << SpreadBase::Table.new(
        'abc', [
          []
        ]
      )

      document.tables << SpreadBase::Table.new(
        'def', [
          [nil]
        ]
      )

      document.tables << SpreadBase::Table.new(
        'ghi', [
          [nil, nil]
        ]
      )

      document.tables << SpreadBase::Table.new(
        'jkl', [
          [nil],
          [1],
          [nil]
        ]
      )

      SpreadBase::Codecs::OpenDocument12.new.encode_to_archive(document)
    end

    it "should drop such row" do
      document = SpreadBase::Codecs::OpenDocument12.new.decode_archive(document_archive)
      tables = document.tables

      assert_size(tables, 4) do |table_1, table_2, table_3, table_4|
        assert_size(table_1.data, 0)

        assert_size(table_2.data, 0)

        assert_size(table_3.data, 0)

        assert_size(table_4.data, 2)
      end
    end
  end

end
