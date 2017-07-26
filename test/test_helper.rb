require 'active_support/core_ext/kernel/reporting'

silence_warnings do
  require 'minitest/spec'
  require 'minitest/autorun'
  require 'inkcite'
end

def assert_contains string, expected_substring, *args
  assert string.include?(expected_substring), *args
end

def assert_error view, *message
  view.errors.any? { |e|
    message.all? { |m| assert_contains(e, m) }
  }.must_equal(true)
end

def assert_no_errors view
  view.errors.must_be_nil
end
