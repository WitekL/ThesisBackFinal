class ComputationController < ApplicationController
  def upload_file
    netlist = params[:netlist].tempfile
    converted_file = FileConverter.new(netlist).call
    result = CircuitSimulator.new(converted_file, simulation_params).call

    touchstone_params = compose_json(result)
    touchstone_file = File.read(result)
    json_response = touchstone_params.merge(file: touchstone_file)

    render json: json_response
  end

  private

  def simulation_params
    {
      start_frequency: params[:start_frequency],
      stop_frequency: params[:stop_frequency],
      points_count: params[:points_count]
    }
  end

  def compose_json(file_name)
    lines = File.readlines(file_name)
    truncated_lines = lines[1..-1]
    splited_lines = truncated_lines.map { |line| line.split(' ') }

    values_hash = splited_lines.map do |line|
      line[1..-1].each_slice(2).map.with_index do |val, index|
        {
          PARAMETERS[index] =>
          {
            re: val[0],
            im: val[1]
          }
        }
      end
    end

    mapped_freq = splited_lines.map.with_index { |line, index| { line[0] => values_hash[index] } }
    { 'parameters' => mapped_freq.inject(&:merge) }
  end

  PARAMETERS = %w[S11 S21 S12 S22]
end
