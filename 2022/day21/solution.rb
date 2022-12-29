# frozen_string_literal: true

require "minitest/autorun"
require "logger"

LOGGER = Logger.new($stderr)
LOGGER.level = Logger::ERROR

class Tree
  ROOT_NODE_ID = "root"
  HUMAN_NODE_ID = "humn"

  class Node
    attr_accessor :value
    attr_reader :id, :children

    def initialize(id)
      @id = id
      @value = nil
      @children = []
    end
  end

  def self.from_input(input)
    tree = input.each_with_object(Hash.new { |h, k| h[k] = Node.new(k) }) do |line, nodes|
      case line
      when /(\w+): (\d+)/
        node = nodes[Regexp.last_match[1]]
        node.value = Regexp.last_match[2].to_i
      when %r{(\w+): (\w+) ([+\-*/]) (\w+)}
        node = nodes[Regexp.last_match[1]]
        node.value = Regexp.last_match[3].to_sym
        node.children << nodes[Regexp.last_match[2]]
        node.children << nodes[Regexp.last_match[4]]
      else
        raise "Line '#{line}' is not correctly formed" unless m
      end
    end

    Tree.new(tree)
  end

  def initialize(tree)
    @tree = tree
  end

  def execute
    root = @tree[ROOT_NODE_ID]
    raise "Root node not found" unless root

    do_execute(root)
  end

  def find_human_yell
    root = @tree[ROOT_NODE_ID]
    second_child_compute = do_execute(root.children.last)
    human_yell = 0
    loop do
      human_yell += 1
      @tree[HUMAN_NODE_ID].value = human_yell
      LOGGER.info "Human yell: '#{human_yell}'"

      first_child_compute = do_execute(root.children.first)
      LOGGER.debug "Comparing #{first_child_compute} and #{second_child_compute}"
      return human_yell if first_child_compute == second_child_compute
    end
  end

  private

  def do_execute(node)
    if %i[+ - * /].include? node.value
      do_execute(node.children.first).send(node.value, do_execute(node.children.last))
    else
      node.value
    end
  end
end

def part1(input)
  Tree.from_input(input).execute
end

def part2(input)
  Tree.from_input(input).find_human_yell
end

class TestSolution < Minitest::Test
  REAL = File.open("input").readlines.map(&:chomp).freeze

  EXAMPLE = DATA.readlines.map(&:chomp)

  def test_part1
    assert_equal 152, part1(EXAMPLE)
  end

  def test_part2
    assert_equal 301, part2(EXAMPLE)
  end

  def test_part1_real
    assert_equal 145_167_969_204_648, part1(REAL)
  end

  def test_part2_real
    assert_equal 3_330_805_295_850, part2(REAL)
  end
end

__END__
root: pppw + sjmn
dbpl: 5
cczh: sllz + lgvd
zczc: 2
ptdq: humn - dvpt
dvpt: 3
lfqf: 4
humn: 5
ljgn: 2
sjmn: drzm * dbpl
sllz: 4
pppw: cczh / lfqf
lgvd: ljgn * ptdq
drzm: hmdt - zczc
hmdt: 32
