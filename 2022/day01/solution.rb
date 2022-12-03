# frozen_string_literal: true

calories = File.open("input.txt")
               .readlines
               .map(&:chomp)
               .each_with_object([0]) do |cal, memo|
                 if cal.empty?
                   memo << 0
                 else
                   memo[-1] += cal.to_i
                 end
               end

puts "Answer (part 1): #{calories.max}"
puts "Answer (part 2): #{calories.sort.reverse[0..2].sum}"
