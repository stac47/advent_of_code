# frozen_string_literal: true

require "minitest/autorun"
require "logger"
require "debug"

LOGGER = Logger.new($stderr)
LOGGER.level = Logger::INFO

# Ruby 3.2 (released on 25th of December, 2022) provides 'Data'
NumberIndex = Data.define(:number, :initial_index)

def move(arr, num)
  return arr if num.number.zero?

  size = arr.size
  index = arr.index(num)
  raise "Cannot find #{num}" unless index

  arr.delete_at(index)
  arr.insert((num.number + index) % (size - 1), num)

  arr
end

class EncryptedFile
  def self.from_input(input, key = 1)
    data = input.each_with_index.map { |n, i| NumberIndex.new(n.to_i * key, i) }

    EncryptedFile.new(data)
  end

  def initialize(data)
    @data = data
  end

  def grove_position(mixes = 1)
    decrypted = decrypt(mixes).map(&:number)
    index_of_zero = decrypted.index(0)
    [
      decrypted[(index_of_zero + 1000) % decrypted.size],
      decrypted[(index_of_zero + 2000) % decrypted.size],
      decrypted[(index_of_zero + 3000) % decrypted.size]
    ]
  end

  private

  def decrypt(mixes)
    decrypted = @data.clone
    mixes.times do |time|
      LOGGER.info "Mixing process: #{time + 1} times"
      mix(decrypted)
    end

    decrypted
  end

  def mix(decrypted)
    @data.each do |n|
      LOGGER.debug "Moving #{n}: #{decrypted}"
      move(decrypted, n)
      LOGGER.debug "Moved  #{n}: #{decrypted}"
    end
  end
end

def part1(input)
  EncryptedFile.from_input(input).grove_position.sum
end

def part2(input)
  key = 811_589_153
  EncryptedFile.from_input(input, key).grove_position(10).sum
end

class TestSolution < Minitest::Test
  REAL = File.open("input").readlines.map(&:chomp).freeze

  EXAMPLE = <<~EXAMPLE
    1
    2
    -3
    3
    -2
    0
    4
  EXAMPLE

  def test_part1
    assert_equal 3, part1(EXAMPLE.split("\n"))
  end

  def test_part2
    assert_equal 1_623_178_306, part2(EXAMPLE.split("\n"))
  end

  def test_part1_real
    assert_equal 2275, part1(REAL)
  end

  def test_part2_real
    assert_equal 4_090_409_331_120, part2(REAL)
  end
end
