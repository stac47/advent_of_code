# frozen_string_literal: true

def part1(input)
  input.each_char.inject(0) do |memo, action|
    action == "(" ? memo + 1 : memo - 1
  end
end

def part2(input)
  input.each_char.with_index.inject(0) do |memo, (action, index)|
    memo = (action == "(" ? memo + 1 : memo - 1)
    break index + 1 if memo == -1

    memo
  end
end

def main
  input = ARGF.readlines.map(&:chomp).first
  puts "Answer (part 1): #{part1(input)}"
  puts "Answer (part 2): #{part2(input)}"
  exit
end

main unless ENV.fetch("RUN_TEST", nil) == "1"

require "minitest/autorun"

class TestSolution < Minitest::Test
  def test_part1
    assert_equal 0, part1("(())")
    assert_equal 0, part1("()()")
    assert_equal 3, part1("(((")
    assert_equal 3, part1("(()(()(")
    assert_equal 3, part1("))(((((")
    assert_equal(-1, part1("())"))
    assert_equal(-1, part1("))("))
    assert_equal(-3, part1(")))"))
    assert_equal(-3, part1(")())())"))
  end

  def test_part2
    assert_equal 1, part2(")")
    assert_equal 5, part2("()())")
  end
end
