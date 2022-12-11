# frozen_string_literal: true

require "minitest/autorun"

# A = X = Rock (1 point)
# B = Y = Paper (2 points)
# C = Z = Scisor (3 points)

OUTCOMES_PART1 = {
  "A X" => 3 + 1,
  "A Y" => 6 + 2,
  "A Z" => 0 + 3,
  "B X" => 0 + 1,
  "B Y" => 3 + 2,
  "B Z" => 6 + 3,
  "C X" => 6 + 1,
  "C Y" => 0 + 2,
  "C Z" => 3 + 3
}.freeze

# A = Rock (1 point)
# B = Paper (2 points)
# C = Scisor (3 points)
# X = Need to loose (0 point)
# Y = Need to draw (3 points)
# Z = Need to win (6 points)
OUTCOMES_PART2 = {
  "A X" => 3 + 0,
  "A Y" => 1 + 3,
  "A Z" => 2 + 6,
  "B X" => 1 + 0,
  "B Y" => 2 + 3,
  "B Z" => 3 + 6,
  "C X" => 2 + 0,
  "C Y" => 3 + 3,
  "C Z" => 1 + 6
}.freeze

def total_points(input, outcomes)
  input.reduce(0) { |memo, line| memo + outcomes[line] }
end

def part1(input)
  total_points(input, OUTCOMES_PART1)
end

def part2(input)
  total_points(input, OUTCOMES_PART2)
end

class TestSolution < Minitest::Test
  INPUT = [
    "A Y",
    "B X",
    "C Z"
  ].freeze

  def test_example_part1
    assert_equal 15, total_points(INPUT, OUTCOMES_PART1)
  end

  def test_example_part2
    assert_equal 12, total_points(INPUT, OUTCOMES_PART2)
  end

  def test_real
    input = File.open("input").readlines.map(&:chomp)
    assert_equal 11_475, part1(input)
    assert_equal 16_862, part2(input)
  end
end
