# frozen_string_literal: true

require "minitest/autorun"

PRIORITIES = (("a".."z").to_a + ("A".."Z").to_a)
             .to_enum
             .with_index
             .reduce({}) do |memo, (k, i)|
               memo.merge!({ k => i + 1 })
             end.freeze

def sum_item_priorities(items)
  items.reduce(0) { |memo, c| memo + PRIORITIES[c] }
end

def common_objects(input)
  input.each_with_object([]) do |line, memo|
    line = line.scan(/\w/)
    compartment1 = line[...(line.size / 2)]
    compartment2 = line[(line.size / 2)...]
    common = compartment1 & compartment2
    common.each { |c| memo << c } unless common.empty?
  end
end

def common_objects_per_groups(input)
  input.to_enum.with_index.each_with_object([]) do |(line, index), memo|
    line = line.scan(/\w/)
    if (index % 3).zero?
      memo.push(line)
    else
      memo[-1] &= line
    end
  end.flatten
end

def part1(input)
  sum_item_priorities(common_objects(input))
end

def part2(input)
  sum_item_priorities(common_objects_per_groups(input))
end

class TestSolution < Minitest::Test
  INPUT = %w[
    vJrwpWtwJgWrhcsFMMfFFhFp
    jqHRNqRjqzjGDLGLrsFMfFZSrLrFZsSL
    PmmdzqPrVvPwwTWBwg
    wMqvLMZHhHMvwLHjbvcjnnSBnvTQFn
    ttgJtRGJQctTZtZT
    CrZsJsPPZsGzwwsLwLmpwMDw
  ].freeze

  def test_priorities
    assert_equal 1, PRIORITIES["a"]
    assert_equal 16, PRIORITIES["p"]
    assert_equal 38, PRIORITIES["L"]
    assert_equal 42, PRIORITIES["P"]
    assert_equal 22, PRIORITIES["v"]
    assert_equal 20, PRIORITIES["t"]
    assert_equal 19, PRIORITIES["s"]
  end

  def test_example1
    assert_equal 157, part1(INPUT)
  end

  def test_example2
    assert_equal 70, part2(INPUT)
  end

  def test_real
    input = File.open("input").readlines.map(&:chomp)
    assert_equal 8493, part1(input)
    assert_equal 2552, part2(input)
  end
end
