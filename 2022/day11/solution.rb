# frozen_string_literal: true

require "minitest/autorun"

Item = Struct.new("Item", :worry_level)
Action = Struct.new("Action", :divisor, :if_true, :if_false)

class Monkey
  attr_reader :id, :action, :inspection_number, :items
  attr_accessor :operation

  def initialize(id)
    @id = id
    @items = []
    @operation = nil
    @action = Action.new
    @inspection_number = 0
  end

  def inspect_item
    @inspection_number += 1
    @items.shift
  end
end

class Game
  attr_reader :monkeys

  def self.parse_input(input)
    monkeys = {}
    current_monkey = nil
    input.each do |line|
      case line
      when /Monkey (\d+)/
        current_monkey = Monkey.new(Regexp.last_match(1).to_i)
      when /  Starting items: (.*)/
        current_monkey.items.concat(Regexp.last_match(1).split(", ").map { |wl| Item.new(wl.to_i) })
      when /  Operation: new = (.*)/
        current_monkey.operation = Regexp.last_match(1)
      when /  Test: divisible by (\d+)/
        current_monkey.action.divisor = Regexp.last_match(1).to_i
      when /    If true: throw to monkey (\d+)/
        current_monkey.action.if_true = Regexp.last_match(1).to_i
      when /    If false: throw to monkey (\d+)/
        current_monkey.action.if_false = Regexp.last_match(1).to_i
      end
      monkeys[current_monkey.id] = current_monkey
    end

    monkeys
  end

  def initialize(input)
    @monkeys = Game.parse_input(input)
  end

  def start(turns, after_worry_level_operation)
    @after_worry_level_operation = after_worry_level_operation
    1.upto(turns) { play_turn }
  end

  private

  def play_turn
    @monkeys.each_value { |monkey| throw_items(monkey) }
  end

  def throw_items(monkey)
    until monkey.items.empty?
      item = monkey.inspect_item
      item.worry_level = compute_worry_level(monkey, item.worry_level)
      recipient_id = (item.worry_level % monkey.action.divisor).zero? ? monkey.action.if_true : monkey.action.if_false
      @monkeys[recipient_id].items << item
    end
  end

  def compute_worry_level(monkey, old)
    operation = monkey.operation.gsub(/old/, old.to_s).split
    new = operation.first.to_i.send(operation[1].to_sym, operation.last.to_i)
    @after_worry_level_operation.call(new)
  end
end

def compute(monkeys)
  monkeys.values.map(&:inspection_number).sort.reverse[0..1].inject(1, &:*)
end

def part1(input)
  game = Game.new(input)
  game.start(20, ->(n) { n / 3 })
  compute(game.monkeys)
end

def part2(input)
  game = Game.new(input)
  common_divisor = game.monkeys.values.map(&:action).map(&:divisor).inject(1, &:*)
  game.start(10_000, ->(n) { n % common_divisor })
  compute(game.monkeys)
end

class TestSolution < Minitest::Test
  EXAMPLE = DATA.readlines.map(&:chomp).freeze

  def test_input_parser
    monkeys = Game.parse_input(EXAMPLE)
    assert_equal 4, monkeys.size
    assert_equal 0, monkeys.values.first.id
    assert_equal 2, monkeys.values.first.items.size
    assert_equal 79, monkeys.values.first.items.first.worry_level
    assert_equal 98, monkeys.values.first.items.last.worry_level
    assert_equal "old * 19", monkeys.values.first.operation
    assert_equal 23, monkeys.values.first.action.divisor
    assert_equal 2, monkeys.values.first.action.if_true
    assert_equal 3, monkeys.values.first.action.if_false
  end

  def test_part1
    assert_equal 10_605, part1(EXAMPLE)
  end

  def test_part2
    assert_equal 2_713_310_158, part2(EXAMPLE)
  end

  def test_real
    input = File.open("input").readlines.map(&:chomp)
    assert_equal 58_786, part1(input)
    assert_equal 14_952_185_856, part2(input)
  end
end

__END__
Monkey 0:
  Starting items: 79, 98
  Operation: new = old * 19
  Test: divisible by 23
    If true: throw to monkey 2
    If false: throw to monkey 3

Monkey 1:
  Starting items: 54, 65, 75, 74
  Operation: new = old + 6
  Test: divisible by 19
    If true: throw to monkey 2
    If false: throw to monkey 0

Monkey 2:
  Starting items: 79, 60, 97
  Operation: new = old * old
  Test: divisible by 13
    If true: throw to monkey 1
    If false: throw to monkey 3

Monkey 3:
  Starting items: 74
  Operation: new = old + 3
  Test: divisible by 17
    If true: throw to monkey 0
    If false: throw to monkey 1
