# frozen_string_literal: true

def compute(input)
  input
end

def main
  input = ARGF.readlines.map(&:chomp)
  puts "Answer: #{compute(input)}"
end

unless ENV.fetch("RUN_TEST", nil) == "1"
  main
  exit
end

require "minitest/autorun"

class TestSolution < Minitest::Test
  def test_compute
    assert_equal 42, compute(0)
  end
end
