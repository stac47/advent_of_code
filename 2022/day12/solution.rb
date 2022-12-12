# frozen_string_literal: true

require "minitest/autorun"

class Position
  attr_reader :x, :y

  def initialize(pos_x, pos_y)
    @x = pos_x
    @y = pos_y
  end

  def eql?(other)
    @x == other.x && @y == other.y
  end

  def hash
    [@x, @y].hash
  end

  def ==(other)
    eql?(other)
  end
end

class Map
  class Node
    attr_reader :position, :height, :letter, :visited, :children

    def initialize(pos_x, pos_y, height, letter)
      @position = Position.new(pos_x, pos_y)
      @height = height
      @letter = letter
      @children = []
      @visited = false
    end

    def visit
      @visited = true
    end

    def unvisit
      @visited = false
    end
  end

  private_constant :Node

  def initialize(input)
    raw = input.map { |line| line.each_char.to_a }
    @nodes = {}
    raw.each.with_index do |row, y|
      row.each.with_index do |c, x|
        height = case c
                 when "S"
                   height_from_letter("a")
                 when "E"
                   height_from_letter("z")
                 else
                   height_from_letter(c)
                 end
        node = Node.new(x, y, height, c)
        @start_node = node if c == "S"
        @end_node = node if c == "E"
        @nodes[Position.new(x, y)] = node
      end
    end

    accessible_positions
  end

  def shortest_path
    shortest_path_from(@start_node)
  end

  def minimal_shortest_path
    @nodes
      .values
      .select { |node| %w[S a].include?(node.letter) }
      .map { |start| shortest_path_from(start) }
      .reject(&:zero?)
      .min
  end

  private

  def shortest_path_from(start)
    @nodes.each_value(&:unvisit)
    walk(start)
  end

  def height_from_letter(letter)
    letter.ord - "a".ord + 1
  end

  def walk(from)
    path_length = 0
    queue = [from]
    until queue.empty?
      level_size = queue.size
      level_size.times do
        node = queue.shift
        return path_length if node.position == @end_node.position

        node.visit
        next_nodes = node.children.reject(&:visited)
        queue.concat(next_nodes)
      end
      path_length += 1
      queue.uniq!(&:position)
    end

    0
  end

  def node_at(position)
    @nodes[position]
  end

  def accessible_positions
    @nodes.each do |current_pos, current_node|
      [
        Position.new(current_pos.x - 1, current_pos.y),
        Position.new(current_pos.x + 1, current_pos.y),
        Position.new(current_pos.x, current_pos.y - 1),
        Position.new(current_pos.x, current_pos.y + 1)
      ].each do |pos|
        node = node_at(pos)
        current_node.children << node if node && node.height - current_node.height <= 1
      end
    end
  end
end

def part1(input)
  Map.new(input).shortest_path
end

def part2(input)
  Map.new(input).minimal_shortest_path
end

class TestSolution < Minitest::Test
  EXAMPLE = <<~MAP
    Sabqponm
    abcryxxl
    accszExk
    acctuvwj
    abdefghi
  MAP

  REAL = File.open("input").readlines.map(&:chomp).freeze

  def test_part1
    assert_equal 31, part1(EXAMPLE.split("\n"))
  end

  def test_part2
    assert_equal 29, part2(EXAMPLE.split("\n"))
  end

  def test_real
    assert_equal 352, part1(REAL)
    assert_equal 345, part2(REAL)
  end
end
