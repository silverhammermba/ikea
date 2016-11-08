require 'set'

class Predictor
  def initialize source
    @initial_counts = Hash.new 0
    @length_counts = Hash.new 0
    @monograph_counts = {}
    @digraph_counts = {}

    @sources = Set.new

    File.open(source) do |f|
      f.each_line do |line|
        name = line.strip.upcase
        next if @sources.include? name
        @sources << name

        @initial_counts[name[0]] += 1
        @length_counts[name.length] += 1
        (0..(name.length - 2)).each do |i|
          @monograph_counts[name[i]] ||= Hash.new 0
          @monograph_counts[name[i]][name[i + 1]] += 1
        end
        (0..(name.length - 3)).each do |i|
          digraph = name[i..(i+1)]
          @digraph_counts[digraph] ||= Hash.new 0
          @digraph_counts[digraph][name[i + 2]] += 1
        end
      end
    end

    # transform length_counts into a cumulative distribution
    @max_length = @length_counts.keys.max
    @max_length.downto(0).each do |i|
      (0...i).each do |j|
        @length_counts[i] += @length_counts[j]
      end
    end

    @totals = {}
    @totals[@length_counts] = @length_counts[@max_length]
    @totals[@initial_counts] = @initial_counts.values.reduce(:+)
    @totals[@monograph_counts] = @monograph_counts.map { |m, n| [m, n.values.reduce(:+)] }.to_h
    @totals[@digraph_counts] = @digraph_counts.map { |d, n| [d, n.values.reduce(:+)] }.to_h
  end

  # predict the next character to be added to the string
  # or nil if the string is long enough
  private def predict_next str
    # simple case of word already being too long
    return nil if str.length >= @max_length

    # test length of word to determine ending
    # TODO choose last letter of word based on source?
    r = rand(@totals[@length_counts])
    return nil if r < @length_counts[str.length]

    case str.length
    when 0
      counts = @initial_counts
      total = @totals[@initial_counts]
    when 1
      counts = @monograph_counts[str[-1]]
      total = @totals[@monograph_counts][str[-1]]
    else
      counts = @digraph_counts[str[-2..-1]]
      total = @totals[@digraph_counts][str[-2..-1]]
    end

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
