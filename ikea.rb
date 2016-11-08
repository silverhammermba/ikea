require 'set'

class Predictor
  def initialize source
    @digraph_counts = {}

    @sources = Set.new

    File.open(source) do |f|
      f.each_line do |line|
        name = line.strip.upcase
        next if @sources.include? name
        @sources << name

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

        last = name[-2..-1]
        @digraph_counts[last] ||= Hash.new 0
        @digraph_counts[last][nil] += 1
      end
    end

    @totals = @digraph_counts.map { |d, n| [d, n.values.reduce(:+)] }.to_h

    p @sources.max_by { |x| x.length }
  end

  # predict the next character to be added to the string
  # or nil if the string is long enough
  private def predict_next str
    while str.length < 2
      str = "^#{str}"
    end

    di = str[-2..-1]

    counts = @digraph_counts[di]
    total = @totals[di]

    # TODO try different counts if nil?
    return nil unless counts

    r = rand(total)
    t = 0
    counts.each do |m, c|
      t += c
      return m if r < t
    end
    raise "failed to randomly select next character"
  end

  # finish predicting str
  def predict str = ""
    n = predict_next str.upcase
    return str unless n
    predict(str + n)
  end

  def predict_new str = ""
    loop do
      result = predict str
      return result unless @sources.include? str
    end
  end
end

pr = Predictor.new ARGV[0]

names = Set.new

100.times do
  name = pr.predict_new
  next if names.include? name
  names << name
end

names.each { |n| puts n }
