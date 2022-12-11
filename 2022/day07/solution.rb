# frozen_string_literal: true

require "minitest/autorun"

TOTAL_SIZE = 70_000_000
NEEDED_SPACE = 30_000_000

class Node
  attr_reader :name, :children, :parent
  attr_accessor :size

  def initialize(name, parent, is_dir: false)
    @name = name
    @size = 0
    @children = []
    @parent = parent
    @is_dir = is_dir
  end

  def directory?
    @is_dir
  end
end

class Command
  class Error < StandardError; end

  LS = "ls"
  CD = "cd"

  ALLOWED_COMMANDS = [LS, CD].freeze

  attr_reader :cmd,
              :argument

  def initialize(line)
    @output = []
    parse(line)
  end

  def add_output_line(line)
    raise Error, "'cd' does not expect any output" if @cmd == CD

    @output << line
  end

  def output_lines
    @output.to_enum
  end

  private

  def parse(line)
    m = /\$ (\w+) ?(.*)/.match(line)
    raise Error, "Invalid input '#{line}'" unless m

    @cmd = m[1]
    raise Error, "Unknown command '#{@cmd}'" unless ALLOWED_COMMANDS.include?(@cmd)

    @argument = m[2] unless m[2].empty?
  end
end

class FileSystem
  include Enumerable

  class Error < StandardError; end

  attr_reader :root

  def initialize(script)
    exec_script(script)
  end

  def each
    queue = [@root]
    until queue.empty?
      current_node = queue.shift
      yield current_node
      queue.concat(current_node.children)
    end
  end

  private

  def exec_script(script)
    commands = parse_script(script)
    raise Error, "The first command should be a 'cd'" unless commands.first.cmd == Command::CD

    @root = Node.new(commands.first.argument, nil, is_dir: true)
    current_node = @root
    commands[1..].each do |c|
      case c.cmd
      when Command::LS
        parse_output(c, current_node)
      when Command::CD
        node = if c.argument == ".."
                 current_node.parent
               else
                 current_node.children.find { |n| n.name == c.argument }
               end
        raise Error, "Could not find node '#{c.argument}'" unless node

        current_node = node
      end
    end
  end

  def parse_output(command, parent_node)
    command.output_lines.each do |line|
      case line
      when /dir (\w+)/
        parent_node.children << Node.new(Regexp.last_match(1), parent_node, is_dir: true)
      when /(\d+) (.+)/
        node = Node.new(Regexp.last_match(2), parent_node)
        node.size = Regexp.last_match(1).to_i
        parent_node.children << node
        update_parents_node_size(node)
      end
    end
  end

  def update_parents_node_size(node)
    current_node = node
    while (current_node = current_node.parent)
      current_node.size += node.size
    end
  end

  def parse_script(script)
    script.each_with_object([]) do |line, commands|
      if line.start_with?("$")
        commands << Command.new(line)
        next
      end

      commands.last.add_output_line line
    end
  end
end

def part1(input)
  FileSystem.new(input)
            .select(&:directory?)
            .select { |node| node.size <= 100_000 }
            .sum(&:size)
end

def part2(input)
  fs = FileSystem.new(input)
  available_space = TOTAL_SIZE - fs.root.size
  space_to_free = NEEDED_SPACE - available_space

  fs.select(&:directory?)
    .select { |node| node.size >= space_to_free }
    .min { |lhs, rhs| lhs.size <=> rhs.size }
    .size
end

class TestSolution < Minitest::Test
  INPUT = <<~INPUT
    $ cd /
    $ ls
    dir a
    14848514 b.txt
    8504156 c.dat
    dir d
    $ cd a
    $ ls
    dir e
    29116 f
    2557 g
    62596 h.lst
    $ cd e
    $ ls
    584 i
    $ cd ..
    $ cd ..
    $ cd d
    $ ls
    4060174 j
    8033020 d.log
    5626152 d.ext
    7214296 k
  INPUT

  def test_parse_command_cd
    c = Command.new("$ cd a")
    assert_equal Command::CD, c.cmd
    assert_equal "a", c.argument
  end

  def test_parse_command_ls
    c = Command.new("$ ls")
    assert_equal Command::LS, c.cmd
    assert_nil c.argument
  end

  def test_filesystem_builder
    builder = FileSystem.new(INPUT.split("\n"))
    root = builder.root

    assert_equal "/", root.name
    assert_equal 4, root.children.size
    assert_equal ["a", "b.txt", "c.dat", "d"], root.children.map(&:name)

    assert root.directory?
    assert root.children.first.directory?
    assert !root.children[1].directory?

    assert_equal 48_381_165, root.size
    assert_equal 94_853, root.children.first.size
    assert_equal 14_848_514, root.children[1].size
    assert_equal 24_933_642, root.children.last.size
  end

  def test_part1
    assert_equal 95_437, part1(INPUT.split("\n"))
  end

  def test_part2
    assert_equal 24_933_642, part2(INPUT.split("\n"))
  end

  def test_real
    input = File.open("input").readlines.map(&:chomp)
    assert_equal 1_749_646, part1(input)
    assert_equal 1_498_966, part2(input)
  end
end
