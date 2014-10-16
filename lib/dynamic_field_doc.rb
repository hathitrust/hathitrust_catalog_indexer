module DynamicFieldDocs

  TYPES = {
      # name  =>  suffix, type, indexed, stored
      :stored => ['', 'string', false, true],
      :text => ['_t', 'text', true, false],
      :left => ['_tl', 'text_l', true, false],
      :proper => ['_tp', 'text_proper', true, false],
      :exactish => ['_e', 'exactish', true, false],
      :numeric => ['_n', 'numericID', true, false],
      :int => ['_i', 'int', true, false],
      :string => ['_s', 'string', true, false],
      :pp => ['_pp', 'piped_path', true, false],
      :piped => ['_piped', 'string', false, true],
      :bool => ['_bool', 'boolean', true, true],
  }

  SM = {
      '_s_s' => [:stored, :string],
      '_t' => [:text],
      '_tp' => [:proper],
      '_tl' => [:left],
      '_e'  => [:exactish],
      '_n' => [:numeric],
      '_s' => [:string],
      '_pp' => [:pp],
      '_piped' => [:piped],
      '_bool' => [:bool],
      '_t_s' => [:stored, :text],
      '_st_s' => [:stored, :string, :text],
      '_tl_s' => [:stored, :left, :text],
      '_tp_s' => [:stored, :proper, :text],
      '_tmax' => [:proper, :left, :text],
      '_tmax_s' => [:stored, :proper, :left, :text],
      '_e_s' => [:stored, :exactish],
      '_n_s' => [:stored, :numeric],
      '_se_s' => [:stored, :string, :exactish],
      '_pp_s' => [:pp, :piped],
  }.to_a.sort{|a,b| b[0].size <=> a[0].size}.map{|x| [Regexp.new("\\A(.+)#{x[0]}\\Z"), x[1]]}.each_with_object({}) {|x,h| h[x[0]] = x[1]}


  def to_dfield(field_name, aLambda=nil, &blk)

    outstream = settings["dynamic_field_docs.output_stream"]

    prefix = field_name
    fielddef = [:stored] # default

    SM.each do |pair|
      suffix = pair[0]
      types = pair[1]
      if match = suffix.match(field_name)
        prefix = match[1]
        fielddef = types
        break
      end
    end

    fielddef.each do |fs|
      t = TYPES[fs]
      name = prefix + t[0]
      fieldtype = t[1]
      ind = t[2] ? "indexed" : "not indexed"
      sto = t[3] ? 'stored' : 'not stored'
      outstream.puts '%-25s %-12s %-11s %-11s' % [name, fieldtype, ind, sto]
    end


    to_field(field_name, aLambda, &blk)
  end

end
