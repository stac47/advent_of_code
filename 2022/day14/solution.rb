# frozen_string_literal: true

require "minitest/autorun"
require "debug"

Point = Struct.new("Point", :x, :y)

class Point
  def self.from_string(str)
    Point.new(*str.split(",").map(&:to_i))
  end
end

SAND_START = Point.new(500, 0).freeze

class Cave
  START = "+"
  AIR = "."
  ROCK = "#"
  SAND = "o"

  def initialize(input, infinite_width: false)
    @min_x = @max_x = SAND_START.x
    @max_y = SAND_START.y
    @canvas = [[START]]
    @infinite_width = infinite_width
    parse_input(input)
    add_floor if @infinite_width
  end

  def to_s
    @canvas.each_with_object(String.new) { |row, out| out << row.join << "\n" }
  end

  def drop_sand_unit
    pos = Point.new(SAND_START.x, SAND_START.y)
    return false if get(pos.x, pos.y) != START

    loop do
      if @infinite_width
        handle_infinite_width(pos)
      elsif pos.y >= @max_y || pos.x <= @min_x || pos.x >= @max_x
        return false
      end

      next if move_sand_unit(pos)

      set(pos.x, pos.y, SAND)
      return true
    end
  end

  private

  def handle_infinite_width(pos)
    if pos.x - 1 < @min_x
      resize_canvas([Point.new(pos.x - 1, pos.y)])
      draw_floor
    end
    return unless pos.x + 1 > @max_x

    resize_canvas([Point.new(pos.x + 1, pos.y)])
    draw_floor
  end

  def move_sand_unit(pos)
    if get(pos.x, pos.y + 1) == AIR
      pos.y += 1
      return true
    end
    if get(pos.x - 1, pos.y + 1) == AIR
      pos.x -= 1
      pos.y += 1
      return true
    end
    if get(pos.x + 1, pos.y + 1) == AIR
      pos.x += 1
      pos.y += 1
      return true
    end

    false
  end

  def add_floor
    width = @canvas.first.size
    @canvas << Array.new(width, AIR)
    @canvas << Array.new(width, AIR)
    @max_y += 2
    draw_floor
  end

  def draw_floor
    @canvas[@max_y].each_index { |i| @canvas[@max_y][i] = ROCK }
  end

  def get(x, y)
    @canvas[y][x - @min_x]
  end

  def set(x, y, value)
    @canvas[y][x - @min_x] = value
  end

  def parse_input(input)
    input.each { |line| parse_line(line) }
  end

  def parse_line(line)
    points = line.split(" -> ").map { |s| Point.from_string(s) }
    resize_canvas(points)
    draw(points)
  end

  def draw(points)
    current_point = points.first
    points[1..].each do |point|
      from_x, to_x = [current_point.x, point.x].minmax
      from_x.upto(to_x) { |pos| @canvas[current_point.y][pos - @min_x] = ROCK } if from_x != to_x
      from_y, to_y = [current_point.y, point.y].minmax
      from_y.upto(to_y) { |pos| @canvas[pos][current_point.x - @min_x] = ROCK } if from_y != to_y
      current_point = point
    end
  end

  def resize_canvas(points)
    max_y = points.map(&:y).max
    if max_y > @max_y
      (max_y - @max_y).times { @canvas << Array.new(@max_x - @min_x + 1, AIR) }
      @max_y = max_y
    end
    min_x, max_x = points.map(&:x).minmax
    if min_x < @min_x
      @canvas.each { |row| (@min_x - min_x).times { row.unshift AIR } }
      @min_x = min_x
    end
    return unless max_x > @max_x

    @canvas.each { |row| (max_x - @max_x).times { row.push AIR } }
    @max_x = max_x
  end
end

def count_while
  counter = 0
  counter += 1 while yield
  counter
end

def part1(input)
  cave = Cave.new(input)
  count_while { cave.drop_sand_unit }
end

def part2(input)
  cave = Cave.new(input, infinite_width: true)
  count_while { cave.drop_sand_unit }
end

class TestSolution < Minitest::Test
  REAL = File.open("input").readlines.map(&:chomp).freeze

  EXAMPLE = <<~INPUT
    498,4 -> 498,6 -> 496,6
    503,4 -> 502,4 -> 502,9 -> 494,9
  INPUT

  def test_point
    point = Point.from_string("498, 4")
    assert_equal 498, point.x
    assert_equal 4, point.y
  end

  def test_cave
    cave = Cave.new(EXAMPLE.split("\n").map(&:chomp))
    expected = <<~CAVE
      ......+...
      ..........
      ..........
      ..........
      ....#...##
      ....#...#.
      ..###...#.
      ........#.
      ........#.
      #########.
    CAVE

    assert_equal expected, cave.to_s

    turn1 = <<~CAVE
      ......+...
      ..........
      ..........
      ..........
      ....#...##
      ....#...#.
      ..###...#.
      ........#.
      ......o.#.
      #########.
    CAVE

    assert cave.drop_sand_unit
    assert_equal turn1, cave.to_s

    turn2 = <<~CAVE
      ......+...
      ..........
      ..........
      ..........
      ....#...##
      ....#...#.
      ..###...#.
      ........#.
      .....oo.#.
      #########.
    CAVE

    assert cave.drop_sand_unit
    assert_equal turn2, cave.to_s
  end

  def test_part1
    assert_equal 24, part1(EXAMPLE.split("\n").map(&:chomp))
  end

  def test_part2
    assert_equal 93, part2(EXAMPLE.split("\n").map(&:chomp))
  end

  def test_part1_real
    assert_equal 1003, part1(REAL)
  end

  def test_part2_real
    assert_equal 25_771, part2(REAL)
  end
end
