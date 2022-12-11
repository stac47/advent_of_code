# frozen_string_literal: true

require "minitest/autorun"

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

  def test_real
    input = File.open("input").readlines.map(&:chomp).first
    assert_equal 138, part1(input)
    assert_equal 1771, part2(input)
  end
end
