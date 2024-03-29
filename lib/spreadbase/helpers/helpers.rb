module SpreadBase # :nodoc:

  # Currently generic helper class
  #
  module Helpers

    # Safe alternative to "[ instance ] * repeats", which returns an array filled with the same instance, which is a recipe for a disaster
    #
    # The instance is duplicated Object#clone, when necessary - note that this method is not meant to do a deep copy.
    #
    def make_array_from_repetitions(instance, repetitions)
      (1..repetitions).inject([]) do | cumulative_result, i |
        case instance
        when Integer, Float, BigDecimal, Date, Time, TrueClass, FalseClass, NilClass #, DateTime is a Date
          cumulative_result << instance
        when String, Array
          cumulative_result << instance.clone
        else
          raise "Unsupported class: #{ }"
        end
      end
    end

    # Prints the 2d-array in a nice, fixed-space table
    #
    # _params_:
    #
    # +rows+::                  2d-array of values.
    #                           Empty arrays generate empty strings.
    #                           Entries can be of different sizes; nils are used as filling values to normalize the rows to the same length.
    #
    # _options_:
    #
    # +row_prefix+::            Prefix this string to each row.
    # +with_header+::           First row will be separated from the remaining ones.
    #
    def pretty_print_rows(rows, **options)
      row_prefix   = options[:row_prefix] || ''
      with_headers = options[:with_headers]

      output = ""

      if rows.size > 0
        max_column_sizes = [0] * rows.map(&:size).max

        # Compute maximum widths

        rows.each do | values |
          values.each_with_index do | value, i |
            formatted_value       = pretty_print_value(value)
            formatted_value_width = formatted_value.chars.to_a.size

            max_column_sizes[i] = formatted_value_width if formatted_value_width > max_column_sizes[i]
          end
        end

        # Print!

        output << row_prefix << '+-' + max_column_sizes.map { | size | '-' * size }.join('-+-') + '-+' << "\n"

        print_pattern = '| ' + max_column_sizes.map { | size | "%-#{ size }s" }.join(' | ') + ' |'

        rows.each_with_index do | row, row_index |
          # Ensure that we always have a number of values equal to the max width
          #
          formatted_row_values = (0...max_column_sizes.size).map do | column_index |
            value = row[column_index]

            pretty_print_value(value)
          end

          output << row_prefix << print_pattern % formatted_row_values << "\n"

          if with_headers && row_index == 0
            output << row_prefix << '+-' + max_column_sizes.map { | size | '-' * size }.join('-+-') + '-+' << "\n"
          end
        end

        output << row_prefix << '+-' + max_column_sizes.map { | size | '-' * size }.join('-+-') + '-+' << "\n"
      end

      output
    end

    private

    def pretty_print_value(value)
      case value
      when BigDecimal
        value.to_s('F')
      when Time, DateTime
        value.strftime('%Y-%m-%d %H:%M:%S %z')
      when String, Date, Numeric, TrueClass, FalseClass
        value.to_s
      when nil
        "NIL"
      else
        value.inspect
      end
    end

  end

end
