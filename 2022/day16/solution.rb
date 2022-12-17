# frozen_string_literal: true

require "minitest/autorun"
require "set"
require "logger"

LOGGER = Logger.new($stderr)
LOGGER.level = Logger::ERROR

COUNTDOWN = 30
OPEN_ACTION_DURATION = 1

class Valve
  include Comparable
  attr_reader :label, :connected
  attr_accessor :rate

  def initialize(label)
    @label = label
    @rate = 0
    @connected = []
    @open = false
    @cached_distances = {}
  end

  def to_s
    @label
  end

  def shortest_path_to(other)
    visited = Set.new
    queue = [[self]]
    until queue.empty?
      path = queue.shift
      valve = path.last
      visited << valve
      if valve == other
        return path
      end

      valve.connected.reject { |v| visited.include?(v) }.each do |v|
        new_path = Array.new(path)
        new_path << v
        queue << new_path
      end
    end

    []
  end

  def distance_to(other)
    return @cached_distances[other] if @cached_distances.key? other

    path = shortest_path_to(other)
    raise "Cannot go from #{@label} to #{other.label}" if path.empty?

    @cached_distances[other] = path.size - 1
  end

  def <=>(other)
    @rate <=> other.rate
  end

  def ==(other)
    @label == other.label
  end

  def eql?(other)
    self == other
  end

  def hash
    @label.hash
  end
end

LINE_PATTERN = /Valve ([A-Z]+) has flow rate=(\d+); tunnels? leads? to valves? ([A-Z, ]+)/

def parse_input(input)
  valves = {}
  input.each do |line|
    m = LINE_PATTERN.match(line)
    raise "Malformed line: #{line}" unless m

    valve = valves[m[1]] ||= Valve.new(m[1])
    valve.rate = m[2].to_i
    labels = m[3].split(", ")
    labels.each_with_object(valve.connected) do |label, connected_valves|
      connected_valves << (valves[label] ||= Valve.new(label))
    end
  end

  valves
end

class Path
  attr_reader :valves, :distance

  def initialize(countdown, valves = [], distance = 0)
    @valves = valves
    @distance = distance
    @countdown = countdown
    @pressure = nil
  end

  def to_s
    "#{@valves.map(&:label)} (distance=#{@distance})"
  end

  def add_valve(valve)
    return nil if @valves.include? valve

    distance = @distance + @valves.last.distance_to(valve) + OPEN_ACTION_DURATION
    if distance >= @countdown
      LOGGER.debug "Reject valve #{valve} because distance = #{distance}"
      return nil
    end

    Path.new(@countdown, @valves + [valve], distance)
  end

  def pressure
    return @pressure if @pressure

    countdown = @countdown
    current_valve = @valves.first
    total_pressure = 0
    @valves[1..].each do |valve|
      countdown -= (current_valve.distance_to(valve) + OPEN_ACTION_DURATION)
      total_pressure += (countdown * valve.rate)
      current_valve = valve
    end
    LOGGER.debug "Pressure for #{self} is #{total_pressure}"
    @pressure ||= total_pressure
  end
end

class PressureOptimizer
  START_VALVE_LABEL = "AA"

  def initialize(input)
    @valves = parse_input(input)
  end

  def maximize_pressure
    pressured_valves = @valves.values.reject { |v| v.rate.zero? }
    valid_paths(pressured_valves, COUNTDOWN).map(&:pressure).max
  end

  def maximize_pressure_with_elephant
    countdown = 26
    pressured_valves = @valves.values.reject { |v| v.rate.zero? }

    paths = valid_paths(pressured_valves, countdown)
    max = 0
    paths.each.with_index do |elephant_path, index|
      paths[index..].each do |my_path|
        next if my_path == elephant_path

        pressure = run_parallel_path(elephant_path, my_path, countdown, pressured_valves.size)
        max = [max, pressure].max
      end
    end

    max
  end

  private

  def run_parallel_path(path1, path2, countdown, pressured_valves_number)
    valves_to_open = Hash.new { |hash, key| hash[key] = [] }
    move_along(path1, valves_to_open)
    move_along(path2, valves_to_open)
    pressure = 0
    open_valves = Set.new

    valves_to_open.keys.sort.each do |index|
      if pressured_valves_number == open_valves.size
        break
      end

      valves = valves_to_open[index]
      first_valve = valves.first
      pressure += first_valve.rate * (countdown - index) unless open_valves.include? first_valve
      open_valves << first_valve
      if valves.size == 2
        second_valve = valves.last
        pressure += second_valve.rate * (countdown - index) unless open_valves.include? second_valve
        open_valves << second_valve
      end
    end
    pressure
  end

  def move_along(path, valves_to_open)
    index = 0
    current_valve = path.valves.first
    path.valves[1..].each do |valve|
      offset = current_valve.distance_to(valve) + OPEN_ACTION_DURATION
      index += offset
      valves_to_open[index] << valve
      current_valve = valve
    end
    valves_to_open
  end

  def valid_paths(pressured_valves, countdown)
    start_valve = @valves[START_VALVE_LABEL]
    paths = [Path.new(countdown, [start_valve])]
    loop do
      new_paths = []
      new_paths_created = false
      paths.each do |path|
        LOGGER.debug "Current path #{path}"
        new_paths_from_current = []
        pressured_valves.each do |pressured_valve|
          new_path = path.add_valve(pressured_valve)
          if new_path
            new_paths_from_current << new_path
            new_paths_created = true
            LOGGER.debug "New path created: #{new_path}"
          end
        end
        if new_paths_from_current.empty?
          LOGGER.debug "Could not add any valve to #{path}"
          new_paths << path
        else
          new_paths.concat(new_paths_from_current)
        end
      end
      if new_paths_created
        paths = new_paths
      else
        break
      end
    end

    LOGGER.info "Found #{paths.size} paths"

    paths
  end
end

def part1(input)
  PressureOptimizer.new(input).maximize_pressure
end

def part2(input)
  PressureOptimizer.new(input).maximize_pressure_with_elephant
end

class TestSolution < Minitest::Test
  REAL = File.open("input").readlines.map(&:chomp).freeze
  EXAMPLE = DATA.readlines.map(&:chomp)

  def test_shortest_path
    valves = parse_input(EXAMPLE)
    assert_equal ["AA", "BB"], valves["AA"].shortest_path_to(valves["BB"]).map(&:label)
    assert_equal ["AA", "DD", "CC"], valves["AA"].shortest_path_to(valves["CC"]).map(&:label)
    assert_equal ["AA", "II", "JJ"], valves["AA"].shortest_path_to(valves["JJ"]).map(&:label)
    assert_equal ["AA", "DD", "EE", "FF"], valves["AA"].shortest_path_to(valves["FF"]).map(&:label)
  end

  def test_part1
    assert_equal 1651, part1(EXAMPLE)
  end

  def test_part2
    assert_equal 1707, part2(EXAMPLE)
  end

  def test_part1_real
    assert_equal 1789, part1(REAL)
  end

  def test_part2_real
    assert_equal 2496, part2(REAL)
  end
end

__END__
Valve AA has flow rate=0; tunnels lead to valves DD, II, BB
Valve BB has flow rate=13; tunnels lead to valves CC, AA
Valve CC has flow rate=2; tunnels lead to valves DD, BB
Valve DD has flow rate=20; tunnels lead to valves CC, AA, EE
Valve EE has flow rate=3; tunnels lead to valves FF, DD
Valve FF has flow rate=0; tunnels lead to valves EE, GG
Valve GG has flow rate=0; tunnels lead to valves FF, HH
Valve HH has flow rate=22; tunnel leads to valve GG
Valve II has flow rate=0; tunnels lead to valves AA, JJ
Valve JJ has flow rate=21; tunnel leads to valve II
