# frozen_string_literal: true

require "minitest/autorun"
require "logger"
require "debug"

LOGGER = Logger.new($stderr)
LOGGER.level = Logger::INFO

PIXEL = "#"

Position = Struct.new("Position", :x, :y)

class Position
  def ==(other)
    x == other.x && y == other.y
  end
end

class Rock
  attr_reader :pos

  def self.shape_from_string(shape_str)
    lines = shape_str.split("\n")
    lines.each_with_object([]).with_index do |(line, obj), y|
      line.each_char.with_index do |c, x|
        obj << Position.new(x, lines.size - 1 - y) if c == PIXEL
      end
    end
  end

  def initialize(x_pos, y_pos)
    @pos = Position.new(x_pos, y_pos)
    @shape = shape
  end

  def pixels_at(x_pos, y_pos)
    @shape.map { |pos| Position.new(pos.x + x_pos, pos.y + y_pos) }
  end

  def pixels
    pixels_at(@pos.x, @pos.y)
  end
end

class MinusRock < Rock
  SHAPE = Rock.shape_from_string(<<~SHAPE).freeze
    ####
  SHAPE

  def shape
    SHAPE
  end
end

class PlusRock < Rock
  SHAPE = Rock.shape_from_string(<<~SHAPE).freeze
    .#.
    ###
    .#.
  SHAPE

  def shape
    SHAPE
  end
end

class CornerRock < Rock
  SHAPE = Rock.shape_from_string(<<~SHAPE).freeze
    ..#
    ..#
    ###
  SHAPE

  def shape
    SHAPE
  end
end

class BarRock < Rock
  SHAPE = Rock.shape_from_string(<<~SHAPE).freeze
    #
    #
    #
    #
  SHAPE

  def shape
    SHAPE
  end
end

class SquareRock < Rock
  SHAPE = Rock.shape_from_string(<<~SHAPE).freeze
    ##
    ##
  SHAPE

  def shape
    SHAPE
  end
end

ROCKS_ORDER = [
  MinusRock,
  PlusRock,
  CornerRock,
  BarRock,
  SquareRock
]

class Chamber
  def initialize(jet_pattern)
    @width = 7
    @jet_pattern = jet_pattern
    @jet_pattern_counter = -1
    # @jet_pattern_enum = @jet_pattern.each_char.cycle
    @space = []
    @height = @space.size
  end

  def height
    @height
  end

  def next_jet_pattern_counter
    n = ((@jet_pattern_counter + 1) % @jet_pattern.size)
  end

  def next_direction
    @jet_pattern_counter = next_jet_pattern_counter
    @jet_pattern[@jet_pattern_counter]
  end

  def drop(rock_class)
    rock = rock_class.new(2, @space.size + 3)
    loop do
      horizontal_move(rock, next_direction)
      stopped = vertical_move(rock)
      if stopped
        draw_pixels(rock)
        break
      end
    end

    truncate if rock.instance_of?(MinusRock) && (1..2).include?(rock.pos.x)
  end

  def truncate
    memo = Array.new(@width, false)
    lowest = 0

    do_truncate = false
    @space.reverse_each.with_index do |row, index|
      @width.times do |n|
        memo[n] = true if row[n] == PIXEL
      end

      lowest = index
      if memo.all?
        do_truncate = true
        break
      end
    end

    @space = @space[-lowest..] if do_truncate
    LOGGER.debug "After truncation: \n#{self}"
    if next_jet_pattern_counter.zero? && @space.size == 1
      debugger
    end
  end

  def to_s
    ret = @space.reverse.each_with_object(String.new) { |row, obj| obj << "|#{row.join}|\n" }
    ret << "+"
    @width.times { ret << "-" }
    ret << "+\n"
    ret
  end

  private

  def draw_pixels(rock)
    pixels_positions = rock.pixels
    highest = pixels_positions.map(&:y).max
    @space.size.upto(highest) do
      @space << Array.new(@width, ".")
      @height += 1
    end
    pixels_positions.each do |pos|
      @space[pos.y][pos.x] = PIXEL
    end
    LOGGER.debug "\n#{self}"
  end

  def horizontal_move(rock, direction)
    dx = (direction == "<" ? -1 : 1)
    next_pixels_positions = rock.pixels_at(rock.pos.x + dx, rock.pos.y)
    return if next_pixels_positions.map(&:x).min < 0
    return if next_pixels_positions.map(&:x).max >= @width
    return if coliding?(next_pixels_positions)

    rock.pos.x += dx
  end

  def vertical_move(rock)
    dy = -1
    next_pixels_positions = rock.pixels_at(rock.pos.x, rock.pos.y + dy)
    return true if rock.pos.y + dy < 0
    return true if coliding?(next_pixels_positions)

    rock.pos.y += dy
    false
  end

  def coliding?(positions)
    positions.each do |pos|
      next if pos.y >= @space.size
      return true if @space[pos.y][pos.x] == PIXEL
    end
    false
  end
end


def simulate(input, rocks)
  chamber = Chamber.new(input)
  ROCKS_ORDER.cycle.with_index do |rock_type, index|
    break if index == rocks

    chamber.drop(rock_type)
    LOGGER.info "Dropped #{index + 1} rocks" if index % 10_000 == 0
  end
  chamber.height
end

def part1(input)
  simulate(input, 2022)
end

def part2(input)
  simulate(input, 1_000_000_000_000)
end

class TestSolution < Minitest::Test
  REAL = File.open("input").readlines.map(&:chomp).first.freeze

  EXAMPLE = ">>><<><>><<<>><>>><<<>>><<<><<<>><>><<>>"

  def test_shape
    rock = PlusRock.new(0, 0)
    assert_equal 5, rock.shape.size
    assert rock.shape.include?(Position.new(1, 0))
    assert rock.shape.include?(Position.new(0, 1))
    assert rock.shape.include?(Position.new(1, 1))
    assert rock.shape.include?(Position.new(2, 1))
    assert rock.shape.include?(Position.new(1, 2))
  end

  def test_part1
    assert_equal 3068, part1(EXAMPLE)
  end

  def test_part2
    assert_equal 1_514_285_714_288, part2(EXAMPLE)
  end

  def test_part1_real
    assert_equal 3197, part1(REAL)
  end

  def test_part2_real
    # assert_equal 0, part2(REAL)
  end
end
