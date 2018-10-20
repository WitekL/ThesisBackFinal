class NetlistComposer
  def initialize(params)
    @params = params.to_h
  end

  def call
    elements, last_node = @params[:schematic] == 'T' ? compose_t(@params) : compose_pi(@params)
    netlist = add_sources(elements, last_node, @params)

    write_to_file(netlist)
  end

  private

  def write_to_file(netlist)
    timestamp = Time.zone.now.strftime('%s')
    file_name = File.join(Dir.pwd,"netlists/#{timestamp}")

    File.open("#{file_name}", 'w+') do |f|
      f.puts(netlist)
    end

    file_name
  end

  def add_sources(elements, last_node, params)
    first_source_params = params[:parameters][:firstSource]
    second_source_params = params[:parameters][:secondSource]
    first_source = "p1 0 1 #{first_source_params[:power]} #{first_source_params[:resistance]}\n"
    second_source = "p2 #{last_node} 0 #{second_source_params[:power]} #{second_source_params[:resistance]}\n"

    elements.push(first_source, second_source)
  end

  def compose_t(params)
    start_node = 0
    end_node = 1
    mid_node = 0
    tmp_end_node = 0
    componenet_num = 1
    netlist = []

    params[:elements].each.with_index(1) do |branch, outer|
      branch[1].each.with_index(1) do |element, inner|
        start_node = end_node
        end_node += 1

        mid_node = end_node if params[:elements][:left] == branch[1] && inner == branch[1].length

        if params[:elements][:middle] == branch[1]  && inner == branch[1].length
          tmp_end_node = end_node
          end_node = 0
        end

        if params[:elements][:right] == branch[1] && inner == 1
          start_node = mid_node
          end_node = tmp_end_node + 1
        end

        string = "#{element[:type]}#{componenet_num} #{start_node} #{end_node} #{element[:value]}#{UNITS[element[:type]]}\n"

        componenet_num += 1

        netlist.push(string)
      end
    end

    [netlist, end_node]
  end

  def compose_pi(params)

  end

  UNITS =  { 'r' => '', 'c' => 'uF', 'l' => 'nH' }
end
