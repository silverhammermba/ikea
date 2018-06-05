require 'set'

class Predictor
  def initialize source
    @length_counts = Hash.new 0
    @last_counts = Hash.new 0
    @digraph_counts = {}

    @sources = Set.new

    File.open(source) do |f|
      f.each_line do |line|
        name = line.strip.upcase
        next if @sources.include? name
        @sources << name

        @length_counts[name.length] += 1

        # first letter
        @digraph_counts["^^"] ||= Hash.new 0
        @digraph_counts["^^"][name[0]] += 1

        first = "^#{name[0]}"
        @digraph_counts[first] ||= Hash.new 0
        @digraph_counts[first][name[1]] += 1

        (0..(name.length - 3)).each do |i|
          digraph = name[i..(i+1)]
          @digraph_counts[digraph] ||= Hash.new 0
          @digraph_counts[digraph][name[i + 2]] += 1
        end

        @last_counts[name[-2..-1]] += 1
      end
    end

    # transform length_counts into a cumulative distribution
    @max_length = @length_counts.keys.max
    @max_length.downto(0).each do |i|
      (0...i).each do |j|
        @length_counts[i] += @length_counts[j]
      end
    end
    @length_totals = @length_counts[@max_length]

    @digraph_totals = @digraph_counts.map { |d, n| [d, n.values.reduce(:+)] }.to_h
  end

  private def digraph str
    case str.length
    when 0
      return "^^"
    when 1
      return "^#{str}"
    else
      return str[-2..-1]
    end
  end

  # finish up predicting str, possibly adding one more char
  def predict_end str
    di = digraph str

    counts = @digraph_counts[di]

    return str unless counts

    # collect all of the next letters that are used as endings
    last_hash = Hash.new 0
    counts.each do |k, v|
      last = @last_counts[di[-1] + k]
      if last > 0
        last_hash[k] = last
      end
    end

    unless last_hash.empty?
      total = last_hash.values.reduce(:+)
      r = rand(total)
      t = 0
      last_hash.each do |m, c|
        t += c
        return str + m if r < t
      end
      raise "failed to select final character"
    end

    # no good endings, just cut it off
    str
  end

  # should this string end (according to the source)?
  def should_end? str
    return true if str.length >= @max_length
    return true unless @digraph_counts[digraph str]
    return true if rand(@length_totals) < @length_counts[str.length + 1]

    false
  end

  # add a character to str
  def predict_next str
    di = digraph str

    r = rand @digraph_totals[di]
    t = 0
    @digraph_counts[di].each do |m, c|
      t += c
      return str + m if r < t
    end

    # failed to find a good character
    str
  end

  # finish predicting str
  def predict str = ""
    return predict_end(str) if should_end? str
    predict(predict_next str)
  end

  def predict_new str = ""
    loop do
      result = predict str
      return result unless @sources.include? str
    end
  end
end

pr = Predictor.new ARGV[0]

puts 50.times.map { pr.predict_new ARGV[1] }.uniq
exit

puts pr.predict(ARGV[1])
