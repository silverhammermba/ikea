require 'set'

all_names = Set.new

File.open('ikea2') do |f|
  f.each_line do |line|
    # potted plants are just scientific names
    next if line =~ /\bpotted\s+plant\b/

    words = line.split(/\/|\s/)
    names = words.select { |w| w =~ /^[[:alpha:]]+$/ && w.upcase == w }

    # multi-word names are usually food
    next if names.length > 1 && line !~ /\//

    names.each { |n| all_names << n }
  end
end

all_names.to_a.sort.each { |n| puts n }
