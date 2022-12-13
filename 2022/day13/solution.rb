# frozen_string_literal: true

require "minitest/autorun"

class PacketData
  def self.convert(value)
    converted = case value
                when Integer
                  value
                when Array
                  value.map { |v| PacketData.convert(v) }
                end
    PacketData.new(converted)
  end

  attr_reader :data

  def initialize(data)
    @data = data
  end

  def <=>(other)
    if [@data, other.data].all? { |d| d.instance_of? Integer }
      @data <=> other.data
    elsif [@data, other.data].all? { |d| d.instance_of? Array }
      @data.each.with_index do |data_packet, index|
        break unless other.data[index]

        cmp = data_packet <=> other.data[index]
        return cmp unless cmp.zero?
      end
      @data.size <=> other.data.size
    elsif @data.instance_of?(Integer)
      PacketData.convert([@data]) <=> other
    else
      self <=> PacketData.convert([other.data])
    end
  end
end

class Packet
  def self.from_string(line, dividers: [])
    packet = Packet.new(eval line)
    packet.divider = true if dividers.include? line
    packet
  end

  attr_reader :value
  attr_accessor :divider

  def initialize(value)
    @value = PacketData.convert(value)
    @divider = false
  end

  def <=>(other)
    @value <=> other.value
  end

  def ordered?(other)
    (self <=> other) != 1
  end
end

def part1(input)
  left_right = input.reject(&:empty?).each_with_object([[], []]).with_index do |(line, packets), index|
    packets.first << Packet.from_string(line) if index.even?
    packets.last << Packet.from_string(line) if index.odd?
  end

  left_right.first.zip(left_right.last).each.with_index.sum do |(left, right), index|
    left.ordered?(right) ? index + 1 : 0
  end
end

def part2(input)
  dividers = ["[[2]]", "[[6]]"]
  sorted_packets = input.reject(&:empty?)
                        .concat(dividers)
                        .map { |line| Packet.from_string(line, dividers:) }
                        .sort
  (sorted_packets.index(&:divider) + 1) * (sorted_packets.rindex(&:divider) + 1)
end

class TestSolution < Minitest::Test
  REAL = File.open("input").readlines.map(&:chomp).freeze

  EXAMPLE = DATA.readlines.map(&:chomp).freeze

  def test_part1
    assert_equal 13, part1(EXAMPLE)
  end

  def test_part2
    assert_equal 140, part2(EXAMPLE)
  end

  def test_part1_real
    assert_equal 5_825, part1(REAL)
  end

  def test_part2_real
    assert_equal 24_477, part2(REAL)
  end
end
__END__
[1,1,3,1,1]
[1,1,5,1,1]

[[1],[2,3,4]]
[[1],4]

[9]
[[8,7,6]]

[[4,4],4,4]
[[4,4],4,4,4]

[7,7,7,7]
[7,7,7]

[]
[3]

[[[]]]
[[]]

[1,[2,[3,[4,[5,6,7]]]],8,9]
[1,[2,[3,[4,[5,6,0]]]],8,9]
