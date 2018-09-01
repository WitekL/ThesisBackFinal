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

  def creator
    netlist = NetlistComposer.new(permitted_params).call
    converted_file = FileConverter.new(File.open(netlist)).call
    result = CircuitSimulator.new(converted_file, simulation_params).call

    touchstone_params = compose_json(result)
    touchstone_file = File.read(result)
    json_response = touchstone_params.merge(file: touchstone_file)

    render json: json_response
  end

  private

  def simulation_params
    {
      start_frequency: params[:start_frequency].presence || params[:parameters][:startFrequency],
      stop_frequency: params[:stop_frequency].presence || params[:parameters][:stopFrequency],
      points_count: params[:points_count].presence || params[:parameters][:pointsCount]
    }
  end

  def compose_json(file_name)
    lines = File.readlines(file_name)
    truncated_lines = lines[1..-1]
    splited_lines = truncated_lines.map { |line| line.split(' ') }

    hash_params = {
      'freq' => [],
      're1' => [],
      'im1' => [],
      're2' => [],
      'im2' => [],
      're3' => [],
      'im3' => [],
      're4' => [],
      'im4' => []
    }

    splited_lines.each do |line|
      line.each_with_index do |val, index|
        hash_params[hash_params.keys[index]].push(val)
      end
    end

    hash_params
  end

  def permitted_params
    params.permit!
  end

  PARAMETERS = %w[S11 S21 S12 S22]
end
