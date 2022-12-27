# frozen_string_literal: true

require "minitest/autorun"
require "logger"

LOGGER = Logger.new($stderr)
LOGGER.level = Logger::DEBUG

def part1(input)
  0
end

def part2(input)
  0
end

class TestSolution < Minitest::Test
  REAL = File.open("input").readlines.map(&:chomp).freeze

  def test_part1
    assert_equal 1, part1(0)
  end

  def test_part2
    assert_equal 0, part2(0)
  end

  def test_part1_real
    # assert_equal 0, part1(REAL)
  end

  def test_part2_real
    # assert_equal 0, part2(REAL)
  end
end
