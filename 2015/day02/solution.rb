# frozen_string_literal: true

require "debug"

def needed_paper(x, y, z)
  surfaces = [x * y, x * z, y * z]
  2 * surfaces.sum + surfaces.min
end

def needed_ribbon(dimensions)
  2 * dimensions.min(2).sum + dimensions.inject(1, &:*)
end

def parse_input(input)
  input.map { |line| line.split("x").map(&:to_i) }
end

def part1(input)
  parse_input(input).sum { |dimensions| needed_paper(*dimensions) }
end

def part2(input)
  parse_input(input).sum { |dimensions| needed_ribbon(dimensions) }
end

def main
  input = ARGF.readlines.map(&:chomp)
  puts "Answer (part 1): #{part1(input)}"
  puts "Answer (part 2): #{part2(input)}"
  exit
end

main unless ENV.fetch("RUN_TEST", nil) == "1"

require "minitest/autorun"

class TestSolution < Minitest::Test
  def test_part1
    assert_equal 58, part1(["2x3x4"])
    assert_equal 43, part1(["1x1x10"])
  end

  def test_part2
    assert_equal 34, part2(["2x3x4"])
    assert_equal 14, part2(["1x1x10"])
  end
end
