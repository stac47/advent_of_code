# frozen_string_literal: true

def compute(input)
  0
end

def main
  input = ARGF.readlines.map(&:chomp)
  puts "Answer: #{compute(input)}"
end

return main unless ENV.fetch("RUN_TEST", nil) == "1"

require "minitest/autorun"

class TestSolution < Minitest::Test
  def test_compute
    assert_equal 42, compute(0)
  end
end
