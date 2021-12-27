require 'zip'
require 'rexml/document'

module SpreadBase # :nodoc:

  module Codecs # :nodoc:

    # Interface for OpenDocument 1. encoding/decoding.
    #
    class OpenDocument12

      MANIFEST_XML = %Q[\
<?xml version="1.0" encoding="UTF-8"?>
<manifest:manifest xmlns:manifest="urn:oasis:names:tc:opendocument:xmlns:manifest:1.0" manifest:version="1.2">
  <manifest:file-entry manifest:media-type="application/vnd.oasis.opendocument.spreadsheet" manifest:version="1.2" manifest:full-path="/"/>
  <manifest:file-entry manifest:media-type="text/xml" manifest:full-path="content.xml"/>
</manifest:manifest>] # :nodoc:

      include OpenDocument12Modules::Encoding
      include OpenDocument12Modules::Decoding

      # Encode a Document to an OpenDocument archive.
      #
      # The generated archive contains the strictly necessary data required to have a consistent archive.
      #
      # _params_:
      #
      # +el_document+::                 SpreadBase::Document instance
      #
      # _options_:
      #
      # +prettify+::                    (false )prettifies the content.xml to be human readable.
      #
      # _returns_ the archive as binary string.
      #
      def encode_to_archive(el_document, options={})
        document_buffer = encode_to_content_xml(el_document, options)
        zip_buffer      = ''

        Zip::File.open_buffer(zip_buffer) do | zip_file |
          zip_file.get_output_stream('META-INF/manifest.xml') { |f| f << MANIFEST_XML }
          zip_file.get_output_stream('content.xml') { |f| f << document_buffer }
        end

        zip_buffer
      end

      # Decode an OpenDocument archive.
      #
      # _params_:
      #
      # +zip_buffer+::            archive as binary string.
      #                           if it's been read from the disk, don't forget to read in binary fmode.
      #
      # _options_:
      #
      # +floats_as_bigdecimal+::  (false) decode floats as BigDecimal instead of Float
      #
      # _returns_ the SpreadBase::Document instance.
      #
      def decode_archive(zip_buffer, options={})
        content_xml_data = read_content_xml(zip_buffer)

        decode_content_xml(content_xml_data, options)
      end

      # Utility method; encodes the Document to the content.xml format.
      #
      # _params_:
      #
      # +el_document+::                  SpreadBase::Document instance
      #
      # _options_:
      #
      # +prettify+::                    (false ) prettifies the content.xml to be human readable.
      #
      # _returns_ content.xml as string.
      #--
      # "utility" is a fancy name for testing/utils helper.
      #
      def encode_to_content_xml(el_document, options={})
        prettify = options[:prettify]

        document_xml_root = encode_to_document_node(el_document)
        document_buffer   = prettify ? pretty_xml(document_xml_root) : document_xml_root.to_s

        document_buffer
      end

      # Utility method; decode the content.xml belonging to an OpenDocument archive.
      #
      # _options_:
      #
      # +floats_as_bigdecimal+::        (false) decode floats as BigDecimal instead of Float
      #
      # _returns_ the SpreadBase::Document instance.
      #--
      # "utility" is a fancy name for testing/utils helper.
      #
      def decode_content_xml(content_xml_data, options={})
        root_node = REXML::Document.new(content_xml_data)

        decode_document_node(root_node, options)
      end

      private

      def read_content_xml(zip_buffer)
        io = StringIO.new(zip_buffer)
        if use_rubyzip_3?
          Zip::File.new(io, buffer: true).read('content.xml')
        else
          Zip::File.new(io, false, true).read('content.xml')
        end
      end

      def use_rubyzip_3?
        Gem.loaded_specs['rubyzip'].version >= Gem::Version.create('3.0.0')
      end

      def pretty_xml(document)
        buffer = ""

        xml_formatter = REXML::Formatters::Pretty.new
        xml_formatter.compact = true
        xml_formatter.write(document, buffer)

        buffer
      end

    end

  end

end
