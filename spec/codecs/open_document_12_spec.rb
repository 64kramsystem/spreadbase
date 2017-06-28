# encoding: UTF-8

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
        [ 1,      1.1,        T_BIGDECIMAL ],
        [ T_DATE, T_DATETIME, T_TIME       ],
        [ nil,    'a',        nil          ]
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

    document = SpreadBase::Codecs::OpenDocument12.new.decode_archive(document_archive, :floats_as_bigdecimal => true)

    assert_size(document.tables, 2) do | table_1, table_2 |

      table_1.name.should == 'abc'

      assert_size(table_1.data, 3) do | row_1, row_2, row_3 |

        assert_size(row_1, 3) do | value_1, value_2, value_3 |
          value_1.should == 1
          value_1.should be_a(Fixnum)
          value_2.should == 1.1
          value_2.should be_a(BigDecimal)
          value_3.should == T_BIGDECIMAL
          value_3.should be_a(BigDecimal)
        end

        assert_size(row_2, 3) do | value_1, value_2, value_3 |
          value_1.should == T_DATE
          value_2.should == T_DATETIME
          value_3.should == T_DATETIME
        end

        assert_size(row_3, 3) do | value_1, value_2, value_3 |
          value_1.should == nil
          value_2.should == 'a'
          value_3.should == nil
        end

      end

      table_2.name.should == 'cde'

      assert_size(table_2.data, 0)
    end
  end

  # Not worth testing in detail; just ensure that the pref
  #
  it "should encode the document with makeup (:prettify) - SMOKE" do
    formatter = stub_initializer(REXML::Formatters::Pretty)

    formatter.should_receive(:write)

    SpreadBase::Codecs::OpenDocument12.new.encode_to_archive(@sample_document, :prettify => true)
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

    @sample_document.tables[ 0 ][ 0,  0 ] = string

    # Doesn't encode correctly if the value is not converted
    #
    SpreadBase::Codecs::OpenDocument12.new.encode_to_content_xml(@sample_document)
  end

  it "should decode as BigDecimal" do
    content_xml = SpreadBase::Codecs::OpenDocument12.new.encode_to_content_xml(@sample_document)

    document = SpreadBase::Codecs::OpenDocument12.new.decode_content_xml(content_xml, :floats_as_bigdecimal => true)

    value = document.tables[ 0 ][ 2, 0 ]

    value.should be_a(BigDecimal)
    value.should == T_BIGDECIMAL
  end

end
