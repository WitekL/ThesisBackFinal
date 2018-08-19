class CircuitSimulator
  def initialize(file_name, simulation_params)
    @file_name = file_name
    @simulation_params = simulation_params
  end

  def call
    stringified_netlist = include_simulation_params(read_file, @simulation_params)
    save_to_file(stringified_netlist)

    qucs_dataset = simulate(@file_name)
    touchstone_file = convert_to_touchstone(qucs_dataset)

    touchstone_file
  end

  private

  def include_simulation_params(file, simulation_params)
    simulation_line = compose_simulation_params(simulation_params)
    read_file << simulation_line
  end

  def simulate(file_name)
    timestamp = Time.zone.now.strftime('%s')
    output_file = File.join(Dir.pwd, 'results', "#{timestamp}_result")
    command = "qucsator -i #{file_name} -o #{output_file}"

    system(command)
    output_file
  end

  def convert_to_touchstone(file_name)
    output_file = "#{file_name}_touchstone"
    command = "qucsconv -i #{file_name} -o #{output_file} -if qucsdata -of touchstone"

    system(command)
    output_file
  end

  def save_to_file(file)
    File.open(@file_name, 'w+') do |f|
      f.puts(file)
    end
  end

  def read_file
    file ||= File.readlines(@file_name)
  end

  def compose_simulation_params(params)
    ".SP:SP1 Type=\"lin\" Start=\"#{params[:start_frequency]} GHz\" Stop=\"#{params[:stop_frequency]} GHz\" Points=\"#{params[:points_count]}\" Noise=\"no\" NoiseIP=\"1\" NoiseOP=\"2\" saveCVs=\"no\" saveAll=\"no\""
  end
end
