# frozen_string_literal: true

require "minitest/autorun"

def parse_line(line)
  line.split(",").map do |sections|
    Range.new(*sections.split("-").map(&:to_i))
  end
end

def compute(input)
  overlaps = 0
  input.each do |line|
    ranges = parse_line(line)
    overlaps += 1 if yield(ranges.first.to_a, ranges.last.to_a)
  end

  overlaps
end

def part1(input)
  overlaps = ->(arr1, arr2) { [arr1, arr2].include?(arr1 & arr2) }
  compute(input, &overlaps)
end

def part2(input)
  overlaps_at_all = ->(arr1, arr2) { !(arr1 & arr2).empty? }
  compute(input, &overlaps_at_all)
end

class TestSolution < Minitest::Test
  INPUT = <<~INPUT
    2-4,6-8
    2-3,4-5
    5-7,7-9
    2-8,3-7
    6-6,4-6
    2-6,4-8
  INPUT

  def test_part1
    assert_equal 2, part1(INPUT.split("\n"))
  end

  def test_part2
    assert_equal 4, part2(INPUT.split("\n"))
  end

  def test_real
    input = File.open("input").readlines.map(&:chomp)
    assert_equal 471, part1(input)
    assert_equal 888, part2(input)
  end
end
