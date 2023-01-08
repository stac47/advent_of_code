# frozen_string_literal: true

require "minitest/autorun"
require "logger"

LOGGER = Logger.new($stderr)
LOGGER.level = Logger::DEBUG

class PasswordSolver
  NO_TILE = " "
  OPEN_TILE = "."
  WALL_TILE = "#"

  RIGHT = "R"
  LEFT = "L"

  DIRECTION_RIGHT = 0
  DIRECTION_DOWN = 1
  DIRECTION_LEFT = 2
  DIRECTION_UP = 3

  DIRECTIONS = %w[right down left up]

  Position = Struct.new("Position", :x, :y)

  class Position
    def to_s
      "(#{x}, #{y})"
    end
  end

  def initialize(input)
    @map = []
    map_section_ended = false
    input.each do |line|
      if line.empty?
        map_section_ended = true
        next
      end
      if map_section_ended
        @path = line.scan /\d+|[RL]/
      else
        @map << line.each_char.to_a
      end
    end

    @width = @map.first.size
    @height = @map.size
    @columns = []
    @width.times do |col|
      @columns << @map.map { |row| row[col] }
    end
    @pos = Position.new(@map.first.index(OPEN_TILE), 0)
    @current_direction = DIRECTION_RIGHT
  end

  def password
    follow_path

    1000 * (@pos.y + 1) + 4 * (@pos.x + 1) + @current_direction
  end

  private

  def change_direction(rotation)
    @current_direction = case rotation
                         when RIGHT
                           (@current_direction + 1) % 4
                         when LEFT
                           (@current_direction - 1) % 4
                         end
    LOGGER.debug "New direction: #{DIRECTIONS[@current_direction]}"
  end

  def follow_path
    LOGGER.info "Start position: #{@pos}"
    @path.each do |action|
      LOGGER.debug "Current action #{action}"
      case action
      when RIGHT, LEFT
        change_direction(action)
      when /\d+/
        move(action.to_i)
      else
        raise "Unknown action #{action}"
      end
    end
  end

  def move(tiles)
    tiles.times do
      dx = 0
      dy = 0
      case @current_direction
      when DIRECTION_RIGHT
        dx = 1
      when DIRECTION_UP
        dy = -1
      when DIRECTION_LEFT
        dx = -1
      when DIRECTION_DOWN
        dy = 1
      end
      update_position(dx, dy)
      if @blocked
        LOGGER.debug "Blocked at #{@pos}"
        @blocked = false
        return
      end
    end
  end

  def update_position(dx, dy)
    next_x = @pos.x + dx
    next_y = @pos.y + dy
    case tile_at(next_x, next_y)
    when WALL_TILE
      @blocked = true
      LOGGER.debug "(#{next_x}, #{next_y}) is a wall: blocked at #{@pos}"
    when OPEN_TILE
      LOGGER.debug "(#{next_x}, #{next_y}) is open: moving from #{@pos}"
      @pos.x = next_x
      @pos.y = next_y
    when NO_TILE, nil
      wrap_position(dx, dy)
    else
      raise "Something strange at (#{next_x}, #{next_y})"
    end
    LOGGER.debug "New position: #{@pos}"
  end

  def tile_at(x, y)
    return NO_TILE if x.negative? || x >= @width || y.negative? || y >= @height

    @map[y][x]
  end

  def wrap_position(dx, dy)
    LOGGER.debug "Wrapping position #{@pos} with move (#{dx}, #{dy})"
    if dx.negative?
      open_x = @map[@pos.y].rindex(OPEN_TILE)
      wall_x = @map[@pos.y].rindex(WALL_TILE)
      if wall_x && wall_x > open_x
        @blocked = true
        return
      end

      @pos.x = open_x
    elsif dx.positive?
      open_x = @map[@pos.y].index(OPEN_TILE)
      wall_x = @map[@pos.y].index(WALL_TILE)
      if wall_x && wall_x < open_x
        @blocked = true
        return
      end

      @pos.x = open_x
    elsif dy.negative?
      open_y = @columns[@pos.x].rindex(OPEN_TILE)
      wall_y = @columns[@pos.x].rindex(WALL_TILE)
      if wall_y && wall_y > open_y
        @blocked = true
        return
      end

      @pos.y = open_y
    elsif dy.positive?
      open_y = @columns[@pos.x].index(OPEN_TILE)
      wall_y = @columns[@pos.x].index(WALL_TILE)
      if wall_y && wall_y < open_y
        @blocked = true
        return
      end

      @pos.y = open_y
    end
  end
end

def part1(input)
  PasswordSolver.new(input).password
end

def part2(input)
  0
end

class TestSolution < Minitest::Test
  REAL = File.open("input").readlines.map(&:chomp).freeze

  EXAMPLE = DATA.readlines.map(&:chomp)

  def test_part1
    assert_equal 6032, part1(EXAMPLE)
  end

  def test_part2
    assert_equal 0, part2(0)
  end

  def test_part1_real
    assert_equal 95358, part1(REAL)
  end

  def test_part2_real
    # assert_equal 0, part2(REAL)
  end
end

__END__
        ...#
        .#..
        #...
        ....
...#.......#
........#...
..#....#....
..........#.
        ...#....
        .....#..
        .#......
        ......#.

10R5L5R10L4R5L5
