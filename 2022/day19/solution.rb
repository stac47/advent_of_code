# frozen_string_literal: true

require "minitest/autorun"
require "set"
require "debug"
require "logger"

LOGGER = Logger.new($stderr)
LOGGER.level = Logger::DEBUG

PATTERN = %r{
  Blueprint\s(\d+):\s
  Each\sore\srobot\scosts\s(\d+)\sore\.\s
  Each\sclay\srobot\scosts\s(\d+)\sore\.\s
  Each\sobsidian\srobot\scosts\s(\d+)\sore\sand\s(\d+)\sclay\.\s
  Each\sgeode\srobot\scosts\s(\d+)\sore\sand\s(\d+)\sobsidian\.
}x

ORE = :ore
CLAY = :clay
OBSIDIAN = :obsidian
GEODE = :geode

MINERALS = [ORE, CLAY, OBSIDIAN, GEODE].freeze

class Cost
  MINERALS = [ORE, CLAY, OBSIDIAN].freeze

  attr_accessor *Cost::MINERALS

  def initialize
    @ore = 0
    @clay = 0
    @obsidian = 0
  end

  def [](mineral)
    send(mineral)
  end

  def to_s
    "#{@ore}/#{@clay}/#{@obsidian}"
  end
end

class Blueprint
  attr_reader :id, :costs

  def initialize(id)
    @id = id
    @costs = {
      ore: Cost.new,
      clay: Cost.new,
      obsidian: Cost.new,
      geode: Cost.new
    }
  end

  def max_robots
    @max ||= {
      ore: @costs.each_value.map(&:ore).max,
      clay: @costs.each_value.map(&:clay).max,
      obsidian: @costs.each_value.map(&:obsidian).max
    }
  end

  def to_s
    @costs.to_s
  end
end

class StateSimulator
  class State
    include Comparable

    ORE = 0
    CLAY = 1
    OBSIDIAN = 2
    GEODE = 3

    MINERALS = {
      ore: ORE,
      clay: CLAY,
      obsidian: OBSIDIAN,
      geode: GEODE
    }

    def self.from(state)
      State.new(state.robots.clone, state.quantities.clone)
    end

    attr_reader :robots, :quantities

    def initialize(robots, quantities)
      @robots = robots
      @quantities = quantities
    end

    def robots_number(mineral)
      @robots[MINERALS[mineral]]
    end

    def quantity(mineral)
      @quantities[MINERALS[mineral]]
    end

    def minerals_number
      @minerals_number ||= @quantities.sum
    end

    def remove_quantity(mineral, value)
      @quantities[MINERALS[mineral]] -= value
    end

    def inc_robot(mineral)
      @robots[MINERALS[mineral]] += 1
    end

    def collect
      MINERALS.each_value do |index|
        @quantities[index] += @robots[index]
      end

      self
    end

    def <=>(other)
      [GEODE, OBSIDIAN, CLAY, ORE].each do |index|
        cmp = @robots[index] <=> other.robots[index]
        return cmp unless cmp == 0
      end
      [GEODE, OBSIDIAN, CLAY, ORE].each do |index|
        cmp = @quantities[index] <=> other.quantities[index]
        return cmp unless cmp == 0
      end

      0
    end

    def ==(other)
      @robots == other.robots && @quantities == other.quantities
    end

    def eql?(other)
      self == other
    end

    def hash
      [@robots, @quantities].hash
    end

    def to_s
      "(reserve: #{@quantities.join('/')}, robots: #{@robots.join('/')})"
    end
  end

  attr_reader :blueprint

  def initialize(blueprint, duration = 24)
    @duration = duration
    @blueprint = blueprint
    @level = [State.new([1, 0, 0, 0], [0, 0, 0, 0])]
    @states = Set.new(@level)
    @turn = 0
  end

  def geode_harvest
    1.upto(@duration) do |minute|
      @turn = minute
      LOGGER.debug "Minute #{minute} starts..."
      act
    end

    @level.map { |state| state.quantity(GEODE) }.max
  end

  private

  def affordable_robots(state)
    MINERALS.each_with_object([]) do |mineral, obj|
      obj << mineral if Cost::MINERALS.all? { |m| state.quantity(m) >= @blueprint.costs[mineral][m] }
    end
  end

  def build_robot(mineral, state)
    raise "One of #{MINERALS} expected" unless MINERALS.include? mineral

    Cost::MINERALS.each { |m| state.remove_quantity(m, @blueprint.costs[mineral][m]) }
    state.inc_robot(mineral)
  end

  def add_state(states, state)
    LOGGER.debug "New state #{state} added"
    states << state
    @states << state
  end

  def next_states_from(state)
    next_states = []
    affordable_robots(state).each do |mineral|
      next if mineral != :geode && state.robots_number(mineral) >= @blueprint.max_robots[mineral]

      new_state = State.from(state)
      new_state.collect
      build_robot(mineral, new_state)
      add_state(next_states, new_state)
    end

    new_state = State.from(state).collect
    add_state(next_states, new_state)

    next_states
  end

  def filter_level(states)
    states_by_robots = states.each_with_object(Hash.new { |h, k| h[k] = Set.new }) { |state, obj| obj[state.robots] << state }

    states_by_robots.values.each_with_object([]) do |set, obj|
      obj.concat(set.to_a.sort.reverse[..2])
      # max_minerals = set.map(&:minerals_number).max
      # set.each do |s|
      #   obj << s if s.minerals_number > max_minerals / 2
      # end
    end
  end

  def act
    new_level = []
    @level.each do |state|
      next_states = next_states_from(state)
      new_level.concat(next_states)
    end

    @level = filter_level(new_level)
  end
end

def parse_input(input)
  input.each_with_object([]) do |line, obj|
    m = PATTERN.match(line)
    raise "Malformed line: '#{line}'" unless m

    blueprint = Blueprint.new(m[1].to_i)
    blueprint.costs[:ore].ore = m[2].to_i
    blueprint.costs[:clay].ore = m[3].to_i
    blueprint.costs[:obsidian].ore = m[4].to_i
    blueprint.costs[:obsidian].clay = m[5].to_i
    blueprint.costs[:geode].ore = m[6].to_i
    blueprint.costs[:geode].obsidian = m[7].to_i

    obj << blueprint
  end
end

def part1(input)
  blueprints = parse_input(input)
  blueprints
    .map { |bp| StateSimulator.new(bp) }
    .sum { |sim| sim.blueprint.id * sim.geode_harvest }
end

def part2(input)
  blueprints = parse_input(input)
  blueprints[..2]
    .map { |bp| StateSimulator.new(bp, 32) }
    .inject(1) { |memo, sim| memo * sim.geode_harvest }
end

class TestSolution < Minitest::Test
  REAL = File.open("input").readlines.map(&:chomp).freeze

  EXAMPLE = DATA.readlines.map(&:chomp).each_with_object([String.new]) do |line, obj|
    if line.empty?
      obj << String.new
      next
    end
    obj.last << line.gsub(/^ /, "")
  end.freeze

  def test_parse_input
    assert_equal 2, EXAMPLE.size
    blueprints = parse_input(EXAMPLE)
    assert_equal 2, blueprints.size
    assert_equal 2, blueprints.first.costs[:geode][:ore]
    assert_equal 7, blueprints.first.costs[:geode][:obsidian]
  end

  def test_blueprint1
    blueprint = parse_input(EXAMPLE).first
    sim = StateSimulator.new(blueprint)
    assert_equal 9, sim.geode_harvest
  end

  def test_blueprint1_32minutes
    blueprint = parse_input(EXAMPLE).first
    sim = StateSimulator.new(blueprint, 32)
    assert_equal 56, sim.geode_harvest
  end

  def test_blueprint2
    blueprint = parse_input(EXAMPLE).last
    sim = StateSimulator.new(blueprint)
    assert_equal 12, sim.geode_harvest
  end

  def test_state
    assert_equal StateSimulator::State.new([0, 0, 0, 0], [0, 0, 0, 0]),
                 StateSimulator::State.new([0, 0, 0, 0], [0, 0, 0, 0])
    assert StateSimulator::State.new([0, 0, 0, 0], [0, 0, 0, 0]) < StateSimulator::State.new([1, 0, 0, 0], [0, 0, 0, 0])
    assert StateSimulator::State.new([0, 0, 0, 0], [0, 0, 0, 0]) < StateSimulator::State.new([0, 0, 0, 0], [0, 0, 0, 1])
  end

  def test_part1
    assert_equal 33, part1(EXAMPLE)
  end

  def test_part2
    assert_equal 0, part2(EXAMPLE)
  end

  def test_part1_real
    assert_equal 1382, part1(REAL)
  end

  def test_part2_real
    assert_equal 0, part2(REAL)
  end
end

__END__
Blueprint 1:
  Each ore robot costs 4 ore.
  Each clay robot costs 2 ore.
  Each obsidian robot costs 3 ore and 14 clay.
  Each geode robot costs 2 ore and 7 obsidian.

Blueprint 2:
  Each ore robot costs 2 ore.
  Each clay robot costs 3 ore.
  Each obsidian robot costs 3 ore and 8 clay.
  Each geode robot costs 3 ore and 12 obsidian.
