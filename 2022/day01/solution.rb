# frozen_string_literal: true

def calories(input)
  input.each_with_object([0]) do |cal, memo|
    if cal.empty?
      memo << 0
    else
      memo[-1] += cal.to_i
    end
  end
end

def part1(input)
  calories(input).max
end

def part2(input)
  calories(input).sort.reverse[0..2].sum
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
  def test_real
    input = File.open("input").readlines.map(&:chomp)
    assert_equal 74_711, part1(input)
    assert_equal 209_481, part2(input)
  end
end
