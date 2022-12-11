# frozen_string_literal: true

require "minitest/autorun"

def part1(input)
  0
end

def part2(input)
  0
end

class TestSolution < Minitest::Test
  def test_part1
    assert_equal 1, part1(0)
  end

  def test_part2
    assert_equal 0, part2(0)
  end

  def test_real
    input = File.open("input").readlines.map(&:chomp)
    # assert_equal 0, part1(input)
    # assert_equal 0, part2(input)
  end
end
