module ISO8583

  def self.add_value2text(deserialization_map, value2text_map, string_id)
    return unless value2text_map
    value = deserialization_map[string_id]
    return unless value
    value_info_text = value2text_map[value]
    return unless value_info_text
    text_string_id = "#{string_id}_value2text"
    deserialization_map[ text_string_id ] = value_info_text
  end

  def self.serialize_fixed_subfields(field_number, string_id2subfield, params_hashtable, message)
    identified_subfields = 0
    field_raw_data = ""
    
    index = 0
    
    ignore_rest_message_part = false
    
    string_id2subfield.keys.sort_by { |key| string_id2subfield[key].start_position }.each do 
      |subfield_string_id|
      
      if( index != string_id2subfield[subfield_string_id].start_position )
        raise ArgumentError.new "BM #{field_number}: serializer dont know what data to put on position #{index}. There is a gap in subfields definitions. Next position with definition is #{string_id2subfield[subfield_string_id].start_position}"
      end
      subfield_def = string_id2subfield[ subfield_string_id ]
      subfield_value = params_hashtable[subfield_string_id]
      if( not subfield_value )
        if( subfield_def.mandatory )
          raise ArgumentError.new "BM #{field_number}: Element #{subfield_string_id} is missing from map with values, but it is marked as mandatory"
        end
        # no value & field not mandatory
        index += subfield_def.subfield_length
        ignore_rest_message_part = true
        next
      else
        if( ignore_rest_message_part )
          # we have subfield_value and we are in ignore_rest_message_part mode
          raise ArgumentError.new "BM #{field_number}: Subfield #{subfield_string_id} is filled, but previous subfield was empty, so we could generate an array with gaps"
        else
          # everything is normal here
        end
      end
      encoded_subfield = subfield_def.serialize( subfield_value )
      
      identified_subfields += params_hashtable[subfield_string_id.to_s+"_value2text"] ? 2 : 1
      field_raw_data += encoded_subfield
      index += subfield_def.subfield_length
     end
    
    if( identified_subfields != params_hashtable.length )
        raise ArgumentError.new "BM #{field_number} arguments hashmap has unparsed elements. Identified subfields '#{identified_subfields}'. Elements in hashmap: #{params_hashtable.length}"
    end
    
    field_raw_data
  end
    
  def self.deserialize_fixed_subfields(field_number, string_id2subfield, raw_src, message)
    result_hashmap = Hash.new
    index = 0
    string_id2subfield.keys.sort_by { |key| string_id2subfield[key].start_position }.each do |subfield_string_id|
      if( index != string_id2subfield[subfield_string_id].start_position )
        raise ArgumentError.new "BM #{field_number}: deserializer dont know what data is lcoated on position #{index}. There is a gap/overlapse in subfields definitions."
      end
      subfield_def = string_id2subfield[ subfield_string_id ]
      if( not subfield_def )
        raise ArgumentError.new "BM #{field_number}: cannot find definition for element #{subfield_string_id}."
      end
      raw_subfield_value = raw_src[ index, subfield_def.subfield_length ]
      subfield_length = subfield_def.deserialize( result_hashmap, raw_subfield_value )
      index += subfield_length
    end
    result_hashmap
  end

  def self.serialize_lllxx_subfields(field_number, string_id2subfield, params_hashtable, message)
    identified_subfields = 0
    field_raw_data = ""
    
    params_hashtable.keys.sort_by { |key| key.to_s }.each do 
      |subfield_string_id|
      subfield_value = params_hashtable[subfield_string_id]
      subfield_def = string_id2subfield[ subfield_string_id ]
      if( subfield_def == nil )
        raise ArgumentError.new "BM #{field_number} Unknown subfield with id '#{subfield_string_id}' and value '#{subfield_value.to_s}'"
      end
      encoded_subfield = subfield_def.serialize( subfield_value )
      
      identified_subfields += 1
      field_raw_data = field_raw_data + encoded_subfield
     end
    
    if( identified_subfields != params_hashtable.length )
        raise ArgumentError.new "BM #{field_number} arguments hashmap has unparsed elements. Identified subfields '#{identified_subfields}'. Elements in hashmap: #{params_hashtable.length}"
    end
    
    field_raw_data
  end
    
  def self.deserialize_lllxx_subfields(field_number, numeric_id2subfield, raw_src, message)
    result_hashmap = Hash.new
    index = 0
    while index != raw_src.length
      if( (raw_src.length - index) < 5 )
        raise ArgumentError.new "BM #{field_number}, the rest of the raw data is 1 byte, so we cannot get field_id"
      end
      rest = raw_src[ index .. raw_src.length - 1 ]
      subfield_id = raw_src[index+3 .. index+4].to_i
      subfield_def = numeric_id2subfield[ subfield_id ]
      
      if( subfield_def == nil )
        raise ArgumentError.new "BM #{field_number} Unknown subfield with id '#{subfield_id}', index='#{index}', rest='#{rest}'"
      end
      
      subfield_length = subfield_def.deserialize( result_hashmap, rest  )
      index += subfield_length # 2 is for the prefix
    end # while

    result_hashmap
  end

  def self.array_to_hashmap_fixed_len(hashmap, hashmap_id, raw_array, start_pos, data_len, field_info)
    if raw_array.length < (start_pos + data_len)
      raise ArgumentError.new("#{field_info}: No space in raw array to src value, arr_len=#{raw_array.length}, data_end_pos=#{start_pos + data_len}")
    end
    hashmap[ hashmap_id ] = raw_array[ start_pos .. (start_pos+data_len-1) ]    
    start_pos + data_len
  end
  
  def self.value_to_array(src, raw_array, start_pos, data_len, field_info, mandatory)
    if raw_array.length < (start_pos + data_len)
      raise ArgumentError.new("#{field_info}: No space in raw array to src value, arr_len=#{raw_array.length}, data_end_pos=#{start_pos + data_len}")
    end
    
    unless src or src.length < 1
      if mandatory
        raise ArgumentError.new("#{field_info}: mandatory field is not filled")
      else
        # just skipping
        return
      end
    end
    
    if src.length != data_len
      raise ArgumentError.new("#{field_info}: src_field_length=#{src.length}; dst_field_length=#{data_len}; src='#{src}'")
    end
    
    raw_array[start_pos..(start_pos + data_len - 1)] = src
  end
  
  def self.xx_value_to_array(raw_array, data_len, subfield_num_id1, subfield_str_id1, field_info1, mandatory)
    if (not raw_array) && (not mandatory)
      return ""
    end
    
    if( subfield_num_id1 < 0 || subfield_num_id1 > 99 )
      raise ArgumentError.new("#{field_info1} (subfield_id=#{subfield_num_id1}/#{subfield_str_id1}): subfield_id is not in range 00-99")
    end
    
    subfield_id2 = (subfield_num_id1 < 10 ? "0" : "") + subfield_num_id1.to_s
    
    field_info2 = (field_info2 ? field_info2 + " " : "") + "(subfield_id=#{subfield_num_id1}/#{subfield_str_id1})"
    
    if data_len != raw_array.length
      raise ArgumentError.new("#{field_info1} (subfield_id=#{subfield_num_id1}/#{subfield_str_id1}): provided data length(#{raw_array.length}) differs from required length(#{data_len}). Value is '#{raw_array}'")
    end
    
    subfield_id2 + raw_array
  end
  
  # TODO - this is crap, needs to use the bin list
  def self.credit_card_brand(number)
    digits = number.to_s[0..3].to_i
    case digits
      when 3000..3059, 3600..3699, 3800..3889
        'diners'
      when 3400..3499, 3700..3799
        'amex'
      when 3088..3094, 3096..3102, 3112..3120, 3158..3159, 3337..3349, 3528..3589
        'jcb'
      when 3890..3899
        'carte blanche'
      when 4000..4999
        'visa'
      when 5018, 5020, 5038, 5457, 5888, 5893, 6304, 6759, 6761, 6762, 6763, 0604, 6333, 6220
        'Intl Maestro'
      when 5100..5599, 6000..6799
        'master'
      when 5610
        'australian bankcard'
      when 6011
        'discover'
      else
        'unknown'
    end
  end
end
