# frozen_string_literal: true

require "minitest/autorun"
require "set"
require "forwardable"
require "logger"
require "debug"

LOGGER = Logger.new($stderr)
LOGGER.level = Logger::DEBUG

class Position
  attr_reader :x, :y, :z

  def initialize(x_pos, y_pos, z_pos)
    @x = x_pos
    @y = y_pos
    @z = z_pos
  end

  def ==(other)
    @x == other.x && @y == other.y && @z == other.z
  end

  def eql?(other)
    self == other
  end

  def hash
    [@x, @y, @z].hash
  end

  def to_s
    "(#{@x}, #{@y}, #{@z})"
  end
end

class Node
  extend Forwardable

  def_delegators :@pos, :x, :y, :z

  AIR_TYPE = 0
  LAVA_TYPE = 1

  attr_reader :connected, :pos, :type

  def initialize(x_pos, y_pos, z_pos, type)
    @pos = Position.new(x_pos, y_pos, z_pos)
    @type = type
    @connected = []
  end

  def ==(other)
    @pos == other.pos
  end

  def to_s
    "Node (type=#{@type}) at #{@pos}"
  end
end

class Droplet
  def self.adjacent_positions(pos)
    [
      Position.new(pos.x    , pos.y    , pos.z - 1),

      Position.new(pos.x - 1, pos.y    , pos.z    ),
      Position.new(pos.x + 1, pos.y    , pos.z    ),
      Position.new(pos.x    , pos.y - 1, pos.z    ),
      Position.new(pos.x    , pos.y + 1, pos.z    ),

      Position.new(pos.x    , pos.y    , pos.z + 1),
    ]
  end

  def self.parse_input(input)
    cubes = input.each_with_object({}) do |line, obj|
      node = Node.new(*line.split(",").map(&:to_i), Node::LAVA_TYPE)
      obj[node.pos] = node
    end
    cubes.each_value do |node|
      self.adjacent_positions(node.pos).each do |pos|
        connected_cube = cubes[pos]
        node.connected << connected_cube if connected_cube
      end
    end

    cubes
  end

  def initialize(input)
    @cubes = Droplet.parse_input(input)
    flood_volume
  end

  def surface
    lava_nodes.sum { |node| 6 - node.connected.reject { |n| n.type == Node::AIR_TYPE }.size }
  end

  def exterior_surface
    surface - interior_nodes.sum { |node| 6 - node.connected.reject { |n| n.type == Node::LAVA_TYPE }.size }
  end

  private

  def interior_nodes
    air_nodes = @cubes.values.select { |n| n.type == Node::AIR_TYPE }
    visited_positions = Set.new
    interior_result = []
    air_nodes.each do |air_node|
      next if visited_positions.include? air_node.pos

      node_group = []

      queue = [air_node]
      until queue.empty?
        LOGGER.debug "queue #{queue.map(&:to_s)}"
        node = queue.shift
        LOGGER.debug "Current node #{node}"
        node_group << node
        visited_positions << node.pos
        node.connected.select { |n| n.type == Node::AIR_TYPE }.each do |connected_air_node|
          unless visited_positions.include?(connected_air_node.pos) || queue.include?(connected_air_node)
            queue << connected_air_node
          end
        end
      end
      if node_group.all? { |n| n.connected.size == 6 }
        LOGGER.debug "Interior group detected: #{node_group.map(&:to_s)}"
        interior_result.concat(node_group)
      else
        LOGGER.debug "Rejecting group: #{node_group.map(&:to_s)}"
      end
    end

    interior_result
  end

  def flood_volume
    min_box = Position.new(lava_nodes.map(&:x).min,
                           lava_nodes.map(&:y).min,
                           lava_nodes.map(&:z).min)
    box = Position.new(lava_nodes.map(&:x).max,
                       lava_nodes.map(&:y).max,
                       lava_nodes.map(&:z).max)
    min_box.x.upto(box.x) do |x|
      min_box.y.upto(box.y) do |y|
        min_box.z.upto(box.z) do |z|
          pos = Position.new(x, y, z)
          @cubes[pos] = Node.new(x, y, z, Node::AIR_TYPE) unless @cubes[pos]
        end
      end
    end

    raise "Volume not filled" unless @cubes.size == (box.x - min_box.x + 1) * (box.y - min_box.y + 1) * (box.z - min_box.z + 1)

    @cubes.values.each do |n|
      Droplet.adjacent_positions(n.pos).each do |pos|
        next if pos.x < min_box.x || pos.y < min_box.y || pos.z < min_box.z
        next if pos.x > box.x || pos.y > box.y || pos.z > box.z

        if n.type == Node::AIR_TYPE
          n.connected << @cubes[pos]
        elsif @cubes[pos].type == Node::AIR_TYPE
          n.connected << @cubes[pos]
        end
      end
    end
  end

  def lava_nodes
    @lava_nodes ||= @cubes.values.select { |n| n.type == Node::LAVA_TYPE }
  end

end

def part1(input)
  Droplet.new(input).surface
end

def part2(input)
  Droplet.new(input).exterior_surface
end

class TestSolution < Minitest::Test
  REAL = File.open("input").readlines.map(&:chomp).freeze

  EXAMPLE = DATA.readlines.map(&:chomp).freeze

  def test_part1
    assert_equal 64, part1(EXAMPLE)
  end

  def test_part2
    assert_equal 58, part2(EXAMPLE)
  end

  def test_part1_real
    assert_equal 4418, part1(REAL)
  end

  def test_part2_real
    assert_equal 2486, part2(REAL)
  end
end

__END__
2,2,2
1,2,2
3,2,2
2,1,2
2,3,2
2,2,1
2,2,3
2,2,4
2,2,6
1,2,5
3,2,5
2,1,5
2,3,5
