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
    hashmap[hashmap_id] = raw_array[start_pos..(start_pos + data_len - 1)] 
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
    digits = number.to_s[0..5].to_i
    case digits
      when 300000..305999, 309500..309599, 360000..369618
        'diners'
      when 324000, 337912..349999, 356904, 370000..379999
        'amex'
      when 180000..180099, 213100..213199, 310000, 334021, 352800..356903, 356905..358999
        'jcb'
      when 400000..499999
        'visa'
      when 500003..508406, 560017..561002, 561012, 561062, 561086, 561091..601094, 601200..601299, 601301..606099, 606101, 606106, 606122, 606144, 606163, 606172, 606179, 606257, 606263, 606269, 606274, 606287, 606295, 606299, 606305, 606325, 606329, 606335..606336, 606348, 606357, 606361, 606364..606365, 606372, 606379, 606384, 606401, 606404, 606410, 606441, 606450, 606452, 606457, 606469, 606484, 606801, 607180, 610093..620010, 620013..620026, 620030, 620035, 620048..620088, 620152..620153, 620218, 620518..620531, 621004..621010, 621014..621019, 621021, 621024, 621026, 621028..621030, 621033..621038, 621040..621050, 621053..621077, 621080..621217, 621221..621248, 621250..621427, 621517..621599, 621660..622125, 622433, 622927..622928, 622930..622933, 622935..622940, 622942..622943, 622945..622955, 622957, 622959..622963, 622967..622968, 622971..622980, 622982..622983, 622986, 622989..622998, 626257, 627066..627779, 627781..628182, 629441..631909, 633110, 633128, 633174..633675, 633698..636261, 636325..636366, 636392..636868, 637102..637529, 639000..642457, 663913, 666000..690755
        'intl maestro'
      when 222100..272099, 510000..559999
        'master'
      when 561003..561009, 561013..561060, 561065..561084, 561090
        'australian bankcard'
      when 380000..384099, 384101..384139, 384141..384159, 384161..399999, 601100..601199, 601300, 644000..650484, 650489..651651, 651655..654999, 655002..659999
        'discover'
      else
        'unknown'
    end
  end
end
