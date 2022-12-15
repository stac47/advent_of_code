# frozen_string_literal: true

require "minitest/autorun"
require "forwardable"
require "set"

MAX = 4_000_000

def merge_ranges(ranges)
  return [] if ranges.empty?
  return [ranges.first] if ranges.size == 1

  ranges = ranges.sort { |a, b| a.begin <=> b.begin }
  ranges.each_with_object([ranges.first]) do |i, stack|
    if stack.last.end >= i.begin
      last_interval = stack.pop
      max = [i.end, last_interval.end].max
      stack << (last_interval.begin..max)
    else
      stack << i
    end
  end
end

def taxicab_distance(x1, y1, x2, y2)
  (x1 - x2).abs + (y1 - y2).abs
end

Point = Struct.new("Point", :x, :y)

class Beacon
  extend Forwardable

  def_delegators :@pos, :x, :y

  def initialize(x, y)
    @pos = Point.new(x, y)
  end

  def eql?(other)
    x == other.x && y == other.y
  end

  def hash
    [x, y].hash
  end
end

class Sensor
  extend Forwardable

  def_delegators :@pos, :x, :y

  attr_reader :closest_beacon, :radius

  def initialize(x, y, closest_beacon)
    @pos = Point.new(x, y)
    @closest_beacon = closest_beacon
    @radius = distance_to(@closest_beacon.x, @closest_beacon.y)
  end

  def reach_range_at(pos_y)
    return nil unless can_reach(x, pos_y)

    deltax = @radius - (y - pos_y).abs
    ((x - deltax)..(x + deltax))
  end

  def can_reach(pos_x, pos_y)
    distance_to(pos_x, pos_y) <= @radius
  end

  private

  def distance_to(other_x, other_y)
    taxicab_distance(x, y, other_x, other_y)
  end
end

class Map
  LINE_PATTERN = /Sensor at x=(-?\d+), y=(-?\d+): closest beacon is at x=(-?\d+), y=(-?\d+)/

  def initialize(input)
    @sensors = []
    parse_input(input)
    @beacons = Set.new(@sensors.map(&:closest_beacon))
  end

  def find_impossible_beacons(row)
    ranges = @sensors.map { |sensor| sensor.reach_range_at(row) }.compact
    merged = merge_ranges(ranges)
    merged.sum(&:size) - @beacons.select { |b| b.y == row }.size
  end

  def find_distress_beacon
    hmax = [MAX, horizontal_limit].min
    vmax = [MAX, vertical_limit].min

    0.upto(vmax) do |cur_y|
      ranges = @sensors
               .map { |sensor| sensor.reach_range_at(cur_y) }
               .compact
               .reject { |i| i.begin > hmax || i.end.negative? }
               .map { |i| ([0, i.begin].max)..([hmax, i.end].min) }

      merged = merge_ranges(ranges)
      return Point.new(merged.first.end + 1, cur_y) unless merged.size == 1
    end

    raise StandardError, "Could not find the distress breacon"
  end

  private

  def horizontal_limit
    @sensors.max { |b1, b2| b1.x <=> b2.x }.x
  end

  def vertical_limit
    @sensors.max { |b1, b2| b1.y <=> b2.y }.y
  end

  def parse_input(input)
    input.each do |line|
      m = LINE_PATTERN.match line
      raise StandardError, "Invalid line format: #{line}" unless m

      beacon = Beacon.new(m[3].to_i, m[4].to_i)
      @sensors << Sensor.new(m[1].to_i, m[2].to_i, beacon)
    end
  end
end

def part1(input, row)
  Map.new(input).find_impossible_beacons(row)
end

def part2(input)
  distress_beacon = Map.new(input).find_distress_beacon
  distress_beacon.x * MAX + distress_beacon.y
end

class TestSolution < Minitest::Test
  REAL = File.open("input").readlines.map(&:chomp).freeze

  EXAMPLE = DATA.readlines.map(&:chomp).freeze

  def test_beacon
    beacon = Beacon.new(1, 2)
    assert_equal 1, beacon.x
    assert_equal 2, beacon.y
  end

  def test_merge_ranges
    assert_equal [], merge_ranges([])
    assert_equal [(1..2)], merge_ranges([(1..2)])
    assert_equal [(1..3)], merge_ranges([(1..2), (2..3)])
    assert_equal [(1..2), (3..4)], merge_ranges([(1..2), (3..4)])
    assert_equal [(1..4)], merge_ranges([(1..4), (2..3)])
  end

  def test_part1
    assert_equal 26, part1(EXAMPLE, 10)
  end

  def test_part2
    assert_equal 56_000_011, part2(EXAMPLE)
  end

  def test_part1_real
    assert_equal 5_181_556, part1(REAL, 2_000_000)
  end

  def test_part2_real
    assert_equal 12_817_603_219_131, part2(REAL)
  end
end

__END__
Sensor at x=2, y=18: closest beacon is at x=-2, y=15
Sensor at x=9, y=16: closest beacon is at x=10, y=16
Sensor at x=13, y=2: closest beacon is at x=15, y=3
Sensor at x=12, y=14: closest beacon is at x=10, y=16
Sensor at x=10, y=20: closest beacon is at x=10, y=16
Sensor at x=14, y=17: closest beacon is at x=10, y=16
Sensor at x=8, y=7: closest beacon is at x=2, y=10
Sensor at x=2, y=0: closest beacon is at x=2, y=10
Sensor at x=0, y=11: closest beacon is at x=2, y=10
Sensor at x=20, y=14: closest beacon is at x=25, y=17
Sensor at x=17, y=20: closest beacon is at x=21, y=22
Sensor at x=16, y=7: closest beacon is at x=15, y=3
Sensor at x=14, y=3: closest beacon is at x=15, y=3
Sensor at x=20, y=1: closest beacon is at x=15, y=3
