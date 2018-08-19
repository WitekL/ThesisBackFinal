class FileConverter
  def initialize(file)
    @file = file
    @tmp_file = nil
  end

  def call
    power_sources = read_power_sources(@file)
    file_name = convert_spice_to_qucs(@tmp_file)
    include_power_sources(power_sources, file_name)
  end

  private

  def read_power_sources(file)
    file_lines = file.readlines
    sources = file_lines.select { |line| line =~ /^p/ }

    first_source = sources[0].split(' ')
    second_source = sources[1].split(' ')

    file_lines.delete(sources[0])
    file_lines.delete(sources[1])

    truncate_sources(file_lines)

    read_source_parameters(first_source, second_source)
  end

  def read_source_parameters(first, second)
    first_source = {
      symbol: first[0],
      begin: first[1],
      end: first[2],
      power: first[3],
      int_resistance: first[4]
    }

    second_source = {
      symbol: second[0],
      begin: second[1],
      end: second[2],
      power: second[3],
      int_resistance: second[4]
    }

    [first_source, second_source]
  end

  def truncate_sources(file_lines)
    timestamp = Time.zone.now.strftime('%s')
    file_name = File.join(Dir.pwd,"netlists/#{timestamp}")

    File.open("#{file_name}", "w+") do |f|
      f.puts(file_lines)
    end

    @tmp_file = file_name
  end

  def convert_spice_to_qucs(file_name)
    output_file = "#{file_name}_qucs"
    command = "qucsconv -i #{file_name} -o #{output_file} -if spice -of qucs"

    system(command)

    output_file
  end

  def include_power_sources(sources, file_name)
    file_dump = File.readlines(file_name)
    comments = file_dump.select { |line| line=~ /^#/ }
    clean_file = file_dump - comments

    qucs_sources = sources.map { |source| compose_source(source) }

    clean_file += qucs_sources

    File.open("#{file_name}", 'w+') do |f|
      f.puts(clean_file)
    end

    file_name
  end

  def compose_source(source_params)
    symbol = source_params[:symbol].upcase
    first = source_params[:begin] == '0' ? 'gnd' : "_net#{source_params[:begin]}"
    last = source_params[:end] == '0' ? 'gnd' : "_net#{source_params[:end]}"

    power = "P=\"#{source_params[:power]} dBm\""
    internal_resistance = "Z=\"#{source_params[:int_resistance]} Ohm\""
    number = "Num=\"#{symbol.scan(/\d+/).join('')}\""

    "Pac:#{symbol} #{first} #{last} #{number} #{internal_resistance} #{power} f=\"1 GHz\""
  end
end
