# frozen_string_literal: true

require "set"

class Position
  attr_reader :x, :y

  def initialize(x, y)
    @x = x
    @y = y
  end

  def surrounding
    [
      Position.new(@x - 1, @y),
      Position.new(@x + 1, @y),
      Position.new(@x, @y - 1),
      Position.new(@x, @y + 1),
      # Diagonals are last choices
      Position.new(@x - 1, @y - 1),
      Position.new(@x + 1, @y - 1),
      Position.new(@x - 1, @y + 1),
      Position.new(@x + 1, @y + 1)
    ]
  end

  def next_to?(other)
    ((@x - other.x).abs <= 1) && ((@y - other.y).abs <= 1)
  end

  def ==(other)
    eql?(other)
  end

  def hash
    [@x, @y].hash
  end

  def eql?(other)
    @x == other.x && @y == other.y
  end
end

class Movement
  attr_reader :move, :steps

  UP = "U"
  DOWN = "D"
  LEFT = "L"
  RIGHT = "R"

  def initialize(line)
    @move, @steps = *line.split
    @steps = @steps.to_i
  end
end

def next_position(from, movement)
  case movement.move
  when Movement::UP
    Position.new(from.x, from.y + 1)
  when Movement::DOWN
    Position.new(from.x, from.y - 1)
  when Movement::LEFT
    Position.new(from.x - 1, from.y)
  when Movement::RIGHT
    Position.new(from.x + 1, from.y)
  end
end

class RopeSimulation
  class Error < StandardError; end

  def initialize(rope_size)
    @rope_size = rope_size
    @rope_positions = Array.new(@rope_size, Position.new(0, 0))
    @visited_positions = Set.new
    @visited_positions << @rope_positions.last
  end

  def simulate_move(input)
    input.each do |line|
      movement = Movement.new(line)
      move_rope(movement)
    end
    @visited_positions.size
  end

  private

  def move_rope(movement)
    1.upto(movement.steps) do
      next_head_pos = next_position(@rope_positions.first, movement)
      move_tail(next_head_pos)
      @visited_positions << @rope_positions.last
    end
  end

  def move_tail(next_head_pos)
    new_pos = @rope_positions[1..].each_with_object([next_head_pos]) do |p, np|
      np << (p.next_to?(np.last) ? p : np.last.surrounding.find { |pa| pa.next_to? p })
    end

    raise Error, "Wrong knots number" unless new_pos.size == @rope_size

    @rope_positions = new_pos
  end
end

def part1(input)
  RopeSimulation.new(2).simulate_move(input)
end

def part2(input)
  RopeSimulation.new(10).simulate_move(input)
end

def main
  input = ARGF.readlines.map(&:chomp)
  puts "Answer (part 1): #{part1(input)}"
  puts "Answer (part 2): #{part2(input)}"
  exit
end

main unless ENV.fetch("RUN_TEST", nil) == "1"

require "minitest/autorun"

class TestSolution < Minitest::Test
  INPUT = <<~INPUT
    R 4
    U 4
    L 3
    D 1
    R 4
    D 1
    L 5
    R 2
  INPUT

  OTHER_INPUT = <<~INPUT
    R 5
    U 8
    L 8
    D 3
    R 17
    D 10
    L 25
    U 20
  INPUT

  def test_part1
    assert_equal 13, part1(INPUT.split("\n").map(&:chomp))
  end

  def test_part2
    assert_equal 1, part2(INPUT.split("\n").map(&:chomp))
  end

  def test_part2_other
    assert_equal 36, part2(OTHER_INPUT.split("\n").map(&:chomp))
  end

  def test_position
    s = Set.new
    s << Position.new(1, 2)
    s << Position.new(2, 2)
    s << Position.new(1, 2)
    assert_equal 2, s.size
    assert_equal Position.new(1, 2), Position.new(1, 2)
    assert Position.new(1, 2).next_to?(Position.new(2, 2))
    assert !Position.new(0, 0).next_to?(Position.new(2, 2))
  end

  def test_movement
    m = Movement.new("U 3")
    assert_equal Movement::UP, m.move
    assert_equal 3, m.steps
  end

  def test_real
    input = File.open("input").readlines.map(&:chomp)
    assert 5_710, part1(input)
    assert 2_259, part2(input)
  end
end
