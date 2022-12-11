# frozen_string_literal: true

require "minitest/autorun"

class TreeMap
  def initialize(input)
    @map = input.map { |line| line.scan(/\d/).map(&:to_i) }
    @last_row = @map.size - 1
    @last_column = @map.first.size - 1
  end

  def visible_trees_count
    count = 2 * @last_row + 2 * @last_column
    1.upto(@last_row - 1) do |row|
      1.upto(@last_column - 1) do |col|
        count += 1 if visible_tree(row, col)
      end
    end

    count
  end

  def highest_scenic_score
    score = 0
    1.upto(@last_row - 1) do |row|
      1.upto(@last_column - 1) do |col|
        current_score = tree_score(row, col)

        score = current_score if current_score > score
      end
    end

    score
  end

  private

  def visible_tree(row, col)
    return true if row.zero? || row == @last_row || col.zero? || col == @last_column

    height = @map[row][col]

    current_row = fetch_row(row)
    current_col = fetch_column(col)

    [
      current_row[...col],
      current_row[(col + 1)..],
      current_col[...row],
      current_col[(row + 1)..]
    ].any? { |other_trees| other_trees.all? { |other_height| other_height < height } }
  end

  def tree_score(row, col)
    height = @map[row][col]
    current_row = fetch_row(row)
    current_col = fetch_column(col)
    [
      current_row[...col].reverse,
      current_row[(col + 1)..],
      current_col[...row].reverse,
      current_col[(row + 1)..]
    ].inject(1) { |memo, trees| memo * distance_with_others_trees(trees, height) }
  end

  def distance_with_others_trees(trees, height)
    trees.inject(0) do |memo, h|
      return memo + 1 if h >= height

      memo + 1
    end
  end

  def fetch_row(row)
    @map[row]
  end

  def fetch_column(col)
    cached_columns[col]
  end

  def cached_columns
    @cached_columns ||= (0..@last_column).each_with_object([]) do |col_idx, columns|
      columns << @map.each_with_object([]) { |row, column| column << row[col_idx] }
    end
  end
end

def part1(input)
  TreeMap.new(input).visible_trees_count
end

def part2(input)
  TreeMap.new(input).highest_scenic_score
end

class TestSolution < Minitest::Test
  INPUT = <<~INPUT
    30373
    25512
    65332
    33549
    35390
  INPUT

  def test_part1
    assert_equal 21, part1(INPUT.split("\n"))
  end

  def test_part2
    assert_equal 8, part2(INPUT.split("\n"))
  end

  def test_real
    input = File.open("input").readlines.map(&:chomp)
    assert_equal 1825, part1(input)
    assert_equal 235_200, part2(input)
  end
end
