# frozen_string_literal: true

def part1(input)
  input
end

def part2(input)
  input
end

def main
  input = ARGF.readlines.map(&:chomp)
  puts "Answer (part 1): #{part1(input)}"
  puts "Answer (part 2): #{part2(input)}"
end

unless ENV.fetch("RUN_TEST", nil) == "1"
  main
  exit
end

require "minitest/autorun"

class TestSolution < Minitest::Test
  def test_part1
    assert_equal 0, compute(0)
  end

  def test_part2
    assert_equal 0, compute(0)
  end
end
