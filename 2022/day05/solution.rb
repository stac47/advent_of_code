# frozen_string_literal: true

def parse_stacks(lines)
  stacks = Hash.new { |hash, key| hash[key] = [] }
  lines.each do |line|
    break unless line.include?("[")

    line.scan(/....?/).each.with_index do |el, index|
      crate = el.strip
      stacks[index + 1].unshift(el.strip) unless crate.empty?
    end
  end

  stacks
end

Operation = Struct.new("Operation", :quantity, :origin, :destination)

def parse_operations(lines)
  lines.each_with_object([]) do |line, obj|
    m = /move (\d+) from (\d+) to (\d+)/.match(line)
    next unless m

    obj << Operation.new(m[1].to_i, m[2].to_i, m[3].to_i)
  end
end

def compute(input)
  stacks = parse_stacks(input)
  operations = parse_operations(input)

  yield stacks, operations

  1.upto(stacks.size).each_with_object(String.new) do |index, obj|
    obj << stacks[index].last.gsub(/[\[\]]/, "")
  end
end

def part1(input)
  compute(input) do |stacks, operations|
    operations.each do |operation|
      operation.quantity.times do
        stacks[operation.destination] << stacks[operation.origin].pop
      end
    end
  end
end

def part2(input)
  compute(input) do |stacks, operations|
    operations.each do |operation|
      temp = []
      operation.quantity.times do
        temp << stacks[operation.origin].pop
      end
      stacks[operation.destination].concat(temp.reverse)
    end
  end
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
  INPUT = <<~INPUT
        [D]    
    [N] [C]    
    [Z] [M] [P]
     1   2   3 

    move 1 from 2 to 1
    move 3 from 1 to 3
    move 2 from 2 to 1
    move 1 from 1 to 2
  INPUT

  def test_parse_stacks
    stacks = parse_stacks(INPUT.split("\n"))
    assert_equal 3, stacks.size
    assert_equal "[D]", stacks[2].last
  end

  def test_parse_operations
    operations = parse_operations(INPUT.split("\n"))
    assert_equal 4, operations.size
    assert_equal 1, operations.first.quantity
  end

  def test_part1
    assert_equal "CMZ", part1(INPUT.split("\n"))
  end

  def test_part2
    assert_equal "MCD", part2(INPUT.split("\n"))
  end

  def test_real
    input = File.open("input.txt").readlines.map(&:chomp)
    assert_equal "ZBDRNPMVH", part1(input)
    assert_equal "WDLPFNNNB", part2(input)
  end
end
