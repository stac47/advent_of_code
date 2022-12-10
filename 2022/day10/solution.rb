# frozen_string_literal: true

class Machine
  class Callback
    def initialize(machine)
      @machine = machine
    end
  end

  module Instructions
    NOOP = "noop"
    ADDX = "addx"

    class Base
      attr_reader :operands

      def initialize(operands = [])
        @operands = operands
      end
    end

    class Noop < Base; end

    class Addx < Base
      def increment_value
        operands.first.to_i
      end
    end

    def self.parse(line)
      tokens = line.split
      case tokens.first
      when NOOP
        Noop.new
      when ADDX
        Addx.new(tokens[1..])
      end
    end
  end

  private_constant :Instructions

  attr_reader :reg_x

  def initialize
    @reg_x = 1
    @cycle = 0
    @callbacks = []
  end

  def register_callback(callback)
    @callbacks << callback
  end

  def run(program)
    tick
    program.each do |line|
      case ins = Instructions.parse(line)
      when Instructions::Noop
        tick
      when Instructions::Addx
        tick
        @reg_x += ins.increment_value
        tick
      else
        raise StandardError, "Unknown operation"
      end
    end
  end

  private

  def tick
    @cycle += 1
    @callbacks.each do |cb|
      cb.call(@cycle)
    end
  end
end

class SignalStrengthCallback < Machine::Callback
  INTERESTING_SIGNALS = [20, 60, 100, 140, 180, 220].freeze

  def call(cycle)
    @strength = (@strength || 0) + (cycle * @machine.reg_x) if INTERESTING_SIGNALS.include?(cycle)
  end

  def output
    @strength
  end
end

class ScreenCallback < Machine::Callback
  class Screen
    WIDTH = 40
    HEIGHT = 6

    def initialize
      @display = Array.new(WIDTH * HEIGHT, ".")
      @current_pixel = 0
    end

    def draw_pixel(sprite_hpos)
      (-1..1).map { |n| n + sprite_hpos }.include?(@current_pixel % WIDTH) ? lit : dark
    end

    def to_s
      (1..HEIGHT).each_with_object(String.new) do |n, output|
        output << @display[(WIDTH * (n - 1))...(WIDTH * n)].join << "\n"
      end
    end

    private

    def lit
      display_pixel("#")
    end

    def dark
      display_pixel(".")
    end

    def display_pixel(color)
      raise StandardError, "Screen buffer overflow" if @current_pixel > WIDTH * HEIGHT

      @display[@current_pixel] = color
      @current_pixel += 1
    end
  end

  private_constant :Screen

  def initialize(machine)
    super
    @screen = Screen.new
  end

  def call(_cycle)
    @screen.draw_pixel(@machine.reg_x)
  end

  def output
    @screen.to_s
  end
end

def common_part(input, klass)
  machine = Machine.new
  cb = klass.new(machine)
  machine.register_callback(cb)
  machine.run(input)
  cb.output
end

def part1(input)
  common_part(input, SignalStrengthCallback)
end

def part2(input)
  common_part(input, ScreenCallback)
end

def main
  input = ARGF.readlines.map(&:chomp)
  puts "Answer (part 1): #{part1(input)}"
  puts "Answer (part 2):\n#{part2(input)}"
  exit
end

main unless ENV.fetch("RUN_TEST", nil) == "1"

require "minitest/autorun"

class TestSolution < Minitest::Test
  CRT = <<~CRT
    ##..##..##..##..##..##..##..##..##..##..
    ###...###...###...###...###...###...###.
    ####....####....####....####....####....
    #####.....#####.....#####.....#####.....
    ######......######......######......####
    #######.......#######.......#######.....
  CRT

  CRT_REAL = <<~CRT
    ####.#..#.###..#..#.####.###..#..#.####.
    #....#.#..#..#.#..#.#....#..#.#..#....#.
    ###..##...#..#.####.###..#..#.#..#...#..
    #....#.#..###..#..#.#....###..#..#..#...
    #....#.#..#.#..#..#.#....#....#..#.#....
    ####.#..#.#..#.#..#.####.#.....##..####.
  CRT

  INPUT = DATA.readlines.map(&:chomp).freeze

  def test_part1
    assert_equal 13_140, part1(INPUT)
  end

  def test_part2
    assert_equal CRT, part2(INPUT)
  end

  def test_real
    input = File.open("input").readlines.map(&:chomp)
    assert_equal 14_560, part1(input)
    assert_equal CRT_REAL, part2(input)
  end
end

__END__
addx 15
addx -11
addx 6
addx -3
addx 5
addx -1
addx -8
addx 13
addx 4
noop
addx -1
addx 5
addx -1
addx 5
addx -1
addx 5
addx -1
addx 5
addx -1
addx -35
addx 1
addx 24
addx -19
addx 1
addx 16
addx -11
noop
noop
addx 21
addx -15
noop
noop
addx -3
addx 9
addx 1
addx -3
addx 8
addx 1
addx 5
noop
noop
noop
noop
noop
addx -36
noop
addx 1
addx 7
noop
noop
noop
addx 2
addx 6
noop
noop
noop
noop
noop
addx 1
noop
noop
addx 7
addx 1
noop
addx -13
addx 13
addx 7
noop
addx 1
addx -33
noop
noop
noop
addx 2
noop
noop
noop
addx 8
noop
addx -1
addx 2
addx 1
noop
addx 17
addx -9
addx 1
addx 1
addx -3
addx 11
noop
noop
addx 1
noop
addx 1
noop
noop
addx -13
addx -19
addx 1
addx 3
addx 26
addx -30
addx 12
addx -1
addx 3
addx 1
noop
noop
noop
addx -9
addx 18
addx 1
addx 2
noop
noop
addx 9
noop
noop
noop
addx -1
addx 2
addx -37
addx 1
addx 3
noop
addx 15
addx -21
addx 22
addx -6
addx 1
noop
addx 2
addx 1
noop
addx -10
noop
noop
addx 20
addx 1
addx 2
addx 2
addx -6
addx -11
noop
noop
noop
