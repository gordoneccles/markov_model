require 'byebug'

class MarkovModel
  def initialize(text, k, n = 129)
    @n = 129
    @gram_size = k
    @output_seed = text[0... @gram_size]
    build(text)
  end

  def build(text)
    text += text[0... @gram_size]
    @table = {}

    text[0... text.length - @gram_size].each_char.with_index do |char, i|
      kgram = text[i... i + @gram_size]
      next_char = text[i + @gram_size]

      @table[kgram] = Array.new(@n){ 0 } unless @table[kgram]
      @table[kgram][@n - 1] += 1;
      @table[kgram][next_char.ord] += 1;
    end
  end

  def kgram_count(kgram)
    raise "Invalid kgram" if kgram.length != @gram_size
    @table[kgram][@n - 1]
  end

  def char_frequency_following_kgram(kgram, char)
    raise "Invalid kgram" if kgram.length != @gram_size
    @table[kgram][char]
  end

  def weighted_rand_char(kgram)
    prob = []
    total_count = 0.0

    char_counts = @table[kgram][0... @n - 1]
    char_counts.each{ |count| total_count += count }
    char_counts.each_with_index{ |count, i| prob[i] = count.to_f / total_count }
    sample_probability(prob).chr
  end

  def sample_probability(probabilities)
    sum = 0.0
    roll = rand

    probabilities.each_with_index do |prob, i|
      sum += prob
      return i if sum > roll
    end

    raise "Bad probability array"
  end

  def generate_text(output_length)
    output_text = @table.keys.sample

    (output_length - @gram_size).times do |i|
      kgram = output_text[i... i + @gram_size]
      next_char = self.weighted_rand_char(kgram)
      output_text += next_char
    end

    output_text
  end

end


if __FILE__ == $PROGRAM_NAME
  training_text = ""
  File.open("./data/#{ARGV[0]}") do |f|
    training_text = f.read
  end

  model = MarkovModel.new(training_text, ARGV[1].to_i)
  output_text = model.generate_text(ARGV[2].to_i)
  puts output_text
end
