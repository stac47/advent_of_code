# frozen_string_literal: true

require "minitest/autorun"
require "logger"
require "set"

LOGGER = Logger.new($stderr)
LOGGER.level = Logger::DEBUG

class Position
  attr_reader :x, :y

  def initialize(x_pos, y_pos)
    @x = x_pos
    @y = y_pos
  end

  def ==(other)
    @x == other.x && @y == other.y
  end

  def eql?(other)
    self == other
  end

  def hash
    [@x, @y].hash
  end

  def to_s
    "(#{@x}, #{@y})"
  end
end

class Canvas
  PROPOSITIONS_ORDER = %i[north south west east].freeze

  ELF = "#"
  EMPTY = "."

  def self.from_input(input)
    input = input.split("\n")
    canvas = Canvas.new
    input.each.with_index do |row, y|
      row.each_char.with_index do |c, x|
        canvas.elves << Position.new(x, y) if c == ELF
      end
    end

    canvas
  end

  attr_reader :elves, :turn

  def initialize
    @elves = Set.new
    @turn = 0
  end

  def to_s
    upper_left, bottom_right = size
    canvas = Array.new(bottom_right.y - upper_left.y + 1) { Array.new(bottom_right.x - upper_left.x + 1, EMPTY) }
    @elves.each_with_object(canvas) { |pos, obj| obj[pos.y - upper_left.y][pos.x - upper_left.x] = ELF }
    canvas.each_with_object([]) { |row, obj| obj << row.join }.join("\n")
  end

  def run_turn
    @turn += 1
    LOGGER.debug "Turn #{@turn} starts..."
    # debugger
    elf_propositions = compute_propositions
    return false if elf_propositions.values.none?

    @elves = update_elves(elf_propositions)
    LOGGER.debug "Turn #{@turn} ends."

    true
  end

  def area
    upper_left, bottom_right = size
    (bottom_right.x - upper_left.x + 1) * (bottom_right.y - upper_left.y + 1)
  end

  private

  def size
    min_x, max_x = @elves.map(&:x).minmax
    min_y, max_y = @elves.map(&:y).minmax

    [Position.new(min_x, min_y), Position.new(max_x, max_y)]
  end

  def compute_propositions
    @elves.each_with_object({}) do |elf, obj|
      obj[elf] = next_acceptable_position(elf)
    end
  end

  def update_elves(propositions)
    duplicate_positions = propositions.values.each_with_object(Set.new) do |pos, obj|
      next unless pos

      obj << pos if propositions.values.count(pos) > 1
    end

    propositions.each_with_object(Set.new) do |(elf, next_pos), obj|
      if duplicate_positions.include? next_pos
        LOGGER.debug "Elf at #{elf} does not move: #{next_pos} is duplicate."
        obj << elf
      elsif next_pos.nil?
        LOGGER.debug "Elf at #{elf} does not move: no propositions."
        obj << elf
      else
        LOGGER.debug "Elf at #{elf} moves to #{next_pos}."
        obj << next_pos
      end
    end
  end

  def elf_at?(x, y)
    @elves.include? Position.new(x, y)
  end

  def elf_around?(pos)
    elf_at?(pos.x - 1, pos.y - 1) ||
      elf_at?(pos.x, pos.y - 1) ||
      elf_at?(pos.x + 1, pos.y - 1) ||
      elf_at?(pos.x - 1, pos.y) ||
      elf_at?(pos.x + 1, pos.y) ||
      elf_at?(pos.x - 1, pos.y + 1) ||
      elf_at?(pos.x, pos.y + 1) ||
      elf_at?(pos.x + 1, pos.y + 1)
  end

  def next_acceptable_position(pos)
    return nil unless elf_around? pos

    acceptable = Set.new
    acceptable << :north unless elf_at?(pos.x - 1, pos.y - 1) ||
                                elf_at?(pos.x, pos.y - 1) ||
                                elf_at?(pos.x + 1, pos.y - 1)
    acceptable << :south unless elf_at?(pos.x - 1, pos.y + 1) ||
                                elf_at?(pos.x, pos.y + 1) ||
                                elf_at?(pos.x + 1, pos.y + 1)
    acceptable << :west unless elf_at?(pos.x - 1, pos.y - 1) ||
                               elf_at?(pos.x - 1, pos.y) ||
                               elf_at?(pos.x - 1, pos.y + 1)
    acceptable << :east unless elf_at?(pos.x + 1, pos.y - 1) ||
                               elf_at?(pos.x + 1, pos.y) ||
                               elf_at?(pos.x + 1, pos.y + 1)

    return nil if acceptable.empty?

    sorted_directions = sort_direction(acceptable)
    selected_direction = sorted_directions.first

    LOGGER.debug "Elf at #{pos} proposes direction '#{selected_direction}'."

    move_direction(pos, selected_direction)
  end

  def move_direction(pos, direction)
    case direction
    when :north
      Position.new(pos.x, pos.y - 1)
    when :south
      Position.new(pos.x, pos.y + 1)
    when :west
      Position.new(pos.x - 1, pos.y)
    when :east
      Position.new(pos.x + 1, pos.y)
    end
  end

  def sort_direction(directions)
    sorted = []
    1.upto(PROPOSITIONS_ORDER.size) do |i|
      direction = PROPOSITIONS_ORDER[((i - 1) + (@turn - 1)) % 4]
      sorted << direction if directions.include? direction
    end

    sorted
  end
end

def part1(input)
  canvas = Canvas.from_input(input)
  10.times { canvas.run_turn }
  canvas.area - canvas.elves.size
end

def part2(input)
  canvas = Canvas.from_input(input)
  while canvas.run_turn; end
  canvas.turn
end

class TestSolution < Minitest::Test
  REAL = File.open("input").readlines.map(&:chomp).freeze

  EXAMPLE1 = <<~EXAMPLE
    .....
    ..##.
    ..#..
    .....
    ..##.
    .....
  EXAMPLE

  EXAMPLE2 = <<~EXAMPLE
    ..............
    ..............
    .......#......
    .....###.#....
    ...#...#.#....
    ....#...##....
    ...#.###......
    ...##.#.##....
    ....#..#......
    ..............
    ..............
    ..............
  EXAMPLE

  def test_canvas
    canvas = Canvas.from_input(EXAMPLE1)
    expected = <<~EXPECTED
      ##
      #.
      ..
      ##
    EXPECTED
    assert_equal expected.chomp, canvas.to_s
    canvas.run_turn
    expected = <<~EXPECTED
      ##
      ..
      #.
      .#
      #.
    EXPECTED
    assert_equal expected.chomp, canvas.to_s
    canvas.run_turn
    expected = <<~EXPECTED
      .##.
      #...
      ...#
      ....
      .#..
    EXPECTED
    assert_equal expected.chomp, canvas.to_s
    canvas.run_turn
    expected = <<~EXPECTED
      ..#..
      ....#
      #....
      ....#
      .....
      ..#..
    EXPECTED
    assert_equal expected.chomp, canvas.to_s
  end

  def test_part1
    assert_equal 110, part1(EXAMPLE2)
  end

  def test_part2
    assert_equal 20, part2(EXAMPLE2)
  end

  def test_part1_real
    assert_equal 4123, part1(REAL.join("\n"))
  end

  def test_part2_real
    assert_equal 1029, part2(REAL.join("\n"))
  end
end
