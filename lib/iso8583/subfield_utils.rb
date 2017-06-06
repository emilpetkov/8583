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
      when 352006..359999, 334021, 310000, 213100..213199, 180000..180099
        'jcb'
      when 557713..559999, 510000..557711, 222100..272099
        'master'
      when 360000..369999, 309500..309599, 300000..305999
        'diners'
      when 370000..379999, 337912..349999, 324000
        'amex'
      when 657360..659999, 657351..657358, 657340..657349, 657334..657338, 657328..657330,
        657326, 657324, 657321..657322, 657319, 657307..657310, 657304..657305,
        657301..657302, 657040..657299, 657033..657038, 657021..657030, 657019,
        657017, 656999..657015, 656638, 655921..655999, 655919, 655917, 655851..655915,
        655840..655849, 655833..655838, 655826..655830, 655824, 655821..655822,
        655819, 655813, 655807..655810, 655804..655805, 655651..655802, 655640..655649,
        655634..655638, 655626..655630, 655624, 655621..655622, 655619, 655613..655614,
        655607..655610, 655604..655605, 655059..655602, 655020, 654251..654999,
        654240..654249, 654233..654238, 654226..654230, 654224, 654221..654222,
        654216..654219, 654213..654214, 654207..654210, 654204..654205, 654151..654202,
        654140..654149, 654134..654138, 654126..654130, 654124, 654121..654122,
        654118..654119, 654113..654114, 654107..654110, 654104..654105, 653150..654102,
        651680..652149, 650979..651651, 650728..650900, 650719, 650599..650699,
        650539..650540, 650440..650484, 650120..650404, 650052..650118, 650034,
        650002..650030, 644000..649999, 601300, 601197..601199, 601187..601195,
        601179, 601100..601177, 384161..399999, 384141..384159, 384101..384139,
        380000..384099
        'discover'
      when 457633..499999, 457394..457630, 451417..457392, 438936..451415, 431275..438934,
        401180..431273, 400000..401177
        'visa'
      when 990015, 689099..690149, 676455..681853, 663913..676452, 641484..642491,
        639000..641471, 637102..637529, 636392..636868, 636325..636366, 633698..636261,
        633174..633675, 633110..633128, 629441..631909, 627781..628182, 627391..627779,
        627089..627385, 626257, 622989..622998, 622986, 622982..622983, 622971..622980,
        622967..622968, 622959..622963, 622957, 622955, 622945..622953, 622942..622943,
        622935..622940, 622930..622933, 622927..622928, 622433, 621984..622125,
        621830..621976, 621427, 621356, 621346..621347, 621338, 621326, 621289,
        621260, 621250, 621241, 621092, 621059, 621055..621056, 621019, 610093..620009,
        606801, 606484, 606469, 606457, 606452, 606450, 606441, 606410, 606404,
        606401, 606384, 606379, 606372, 606364..606365, 606361, 606357, 606348,
        606335..606336, 606329, 606325, 606305, 606299, 606295, 606287, 606274,
        606269, 606263, 606257, 606179, 606172, 606163, 606144, 606122, 606106,
        606101, 606072..606099, 604400..606070, 603712..604200, 603696..603704,
        603607..603693, 603523..603599, 603395..603521, 602970..603358, 601301..602968,
        601200..601299, 600206..601094, 589658..599900, 561091..589655, 561086,
        561062, 561056..561059, 561012, 560017..561002, 508100..508406, 507187..507857,
        504176..506122, 502000..504174, 500003..501898
        'intl maestro'
      when 561090, 561065..561084, 561060, 561013..561047, 561003..561009
        'australian bankcard'
      else
        'unknown'
    end
  end
end
