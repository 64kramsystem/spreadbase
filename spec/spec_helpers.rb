require 'date'
require 'bigdecimal'

module SpecHelpers

  T_DATE       = Date.new(2012, 4, 10)
  T_DATETIME   = DateTime.new(2012, 4, 11, 23, 33, 42)
  T_TIME       = Time.new(2012, 4, 11, 23, 33, 42, "+02:00")
  T_BIGDECIMAL = BigDecimal.new('1.33')

  # This method is cool beyond any argument about the imperfect name.
  #
  def assert_size(collection, expected_size)
    collection.size.should == expected_size

    yield(*collection) if block_given?
  end

  def stub_initializer(klazz, *args)
    instance = klazz.new(*args)

    klazz.stub!(:new).and_return(instance)

    instance
  end

end
