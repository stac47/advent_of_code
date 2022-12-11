# frozen_string_literal: true

require "minitest/autorun"
require "set"

def first_unique_char_sequence(len, line)
  0.upto(line.size - len) do |n|
    return n + len if line[n...(n + len)].each_char.to_set.size == len
  end
end

def part1(input) = first_unique_char_sequence(4, input)
def part2(input) = method(:first_unique_char_sequence).curry.call(14).call(input)

class TestSolution < Minitest::Test
  def test_find_marker
    assert_equal 7, part1("aaaabcd")
    assert_equal 7, part1("mjqjpqmgbljsphdztnvjfqwrcgsmlb")
    assert_equal 5, part1("bvwbjplbgvbhsrlpgdmjqwftvncz")
    assert_equal 6, part1("nppdvjthqldpwncqszvftbrmjlhg")
    assert_equal 10, part1("nznrnfrfntjfmvfwmzdfjlvtqnbhcprsg")
    assert_equal 11, part1("zcfzfwzzqfrljwzlrfnpqdbhtmscgvjw")

    assert_equal 19, part2("mjqjpqmgbljsphdztnvjfqwrcgsmlb")
    assert_equal 23, part2("bvwbjplbgvbhsrlpgdmjqwftvncz")
    assert_equal 23, part2("nppdvjthqldpwncqszvftbrmjlhg")
    assert_equal 29, part2("nznrnfrfntjfmvfwmzdfjlvtqnbhcprsg")
    assert_equal 26, part2("zcfzfwzzqfrljwzlrfnpqdbhtmscgvjw")
  end

  def test_real
    input = File.open("input").readlines.map(&:chomp).first
    assert_equal 1655, part1(input)
    assert_equal 2665, part2(input)
  end
end
