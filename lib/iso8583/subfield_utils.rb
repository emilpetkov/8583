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

  def self.serialize_lll_ebcdic_subfield(additional_data)
    "".force_encoding('ASCII-8BIT').tap do |serialized_string|
      additional_data.each do |name, data|
        number = PAYNETICS_SUBFIELD_DEFINITIONS[name][:number]
        # Encode the length of subfield number + data in EBCDIC
        length = LLL_EBCDIC.encode((number + data).length, nil)
        # Encode the subfield number in EBCDIC
        number = LL_EBCDIC.encode(number, nil)
        # Encode the actual data in the format
        data = PAYNETICS_SUBFIELD_DEFINITIONS[name][:codec].encode(data)
        # Join the encoded length, encoded subfield number and actual data
        encoded_data = length + number + data
        serialized_string << encoded_data
      end
    end
  end

  def self.deserialize_lll_ebcdic_subfield(raw_additional_data)
    #\xF0\xF0\xF4 \xF4\xF0\xF0\xF7 \xF0\xF0\xF6 \xF3\xF0\xF0\xF2\xF9\xF9
    # Algorithm to iterate over the serialized fields. Each iteration loops over
    # one serialized field
    {}.tap do |deserialized_fields|
      index = 0
      length_prefix = PAYNETICS_SUBFIELD_LENGTH_PREFIX
      while index < raw_additional_data.length
        # Get the length of the field
        length = ISO8583.ebcdic2ascii(raw_additional_data[index...index + length_prefix]).to_i
        # Get the encoded payload of the field
        data = raw_additional_data[(index + length_prefix)...(index + length_prefix +length)]

        field_number = ISO8583.ebcdic2ascii(data[0, PAYNETICS_SUBFIELD_NUMBER_LENGTH]).to_i
        field_definition = PAYNETICS_SUBFIELD_DEFINITIONS.values.detect { |k, _v| k[:number].to_i == field_number }

        # Decode the payload with the proper codec
        actual_data = field_definition[:codec].decode(data[PAYNETICS_SUBFIELD_NUMBER_LENGTH, data.length])
        # Add the deserialized field to the response object
        deserialized_fields[field_definition[:name]] = actual_data
        # Get the total length of the field and add it to the index for the next iteration
        subfield_length = data.length + length_prefix

        index += subfield_length
      end
    end
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
      when 300000..305999, 309500..309599, 360000..360779, 361219..361228, 361232,
        361235..361259, 361261..361269, 361271..361273, 361295..361298, 361300..361320,
        361322, 361324..361346, 361349..361423, 361430..361449, 361474..361475,
        361477..361480, 361482..361489, 361558, 361600..361899, 361991..361999,
        362050..362053, 362056, 362058..362063, 362065..362138, 362141,
        362191..362196, 362200..362309, 362312, 362331..362339, 362343, 362345,
        362347, 362352..362365, 362368..362377, 362383..362385, 362392..362396,
        362402..362405, 362500..362503, 362509..362518, 362524..362530, 362535..362537,
        362543..362553, 362555..362560, 362563, 362600..362601, 362611..362614,
        362620..362622, 362627..362634, 363000, 363300..363599, 363999..364003,
        364006..364060, 364062..364064, 364067..364070, 364072..364090, 364093..364199,
        364201..364205, 364211..364214, 364216..364219, 364222..364224, 364226..364232,
        364234..364267, 364269..364285, 364287..364412, 364414..364436, 364441..364445,
        364447..364465, 364467, 364470..364480, 364482..364483, 364485..364489,
        364491, 364493..364500, 364502, 364504..364514, 364516..364518,
        364521..364525, 364527..364547, 364560..364564, 364568..364569, 364571..364588,
        364590..364595, 364598, 364601..364606, 364610, 364612..364620, 364630,
        364632..364639, 364660..364667, 364671..364673, 364680..364689, 364700..364706,
        364708, 364710..364726, 364730..364759, 364770..364772, 364776..364795,
        364797..364799, 364810..364812, 364814..364816, 364821..364823, 364825..364830,
        364836..364871, 364873, 364875..364878, 364880, 364882..364884, 364886..364888,
        364900..364901, 364910, 365001..365023, 365025..365048, 365120..365129,
        365132..365158, 365162..365164, 365166..365183, 365185..365191, 365197..365206,
        365217..365219, 365221, 365228..365230, 365251..365256, 365298..365299,
        365350..365394, 365400..365415, 365420..365429, 365431..365432, 365450,
        365452..365475, 365477..365488, 365494, 365502..365523, 365525..365530,
        365532, 365534..365535, 365537..365539, 365542, 365560..365574,
        365588..365593, 365595..365603, 365617..365619, 365628..365632, 365636,
        365645..365646, 365649, 365700..365702, 366000..366499, 366510..366629,
        366762, 367000..367099, 369000..369146, 369148..369149, 369160..369199,
        369210..369215, 369400..369599, 369610, 369613..369614, 369616..369618,
        369810..369999
        'diners'
      when 324000, 337912..337913, 337941, 340000..344289, 344294, 344301,
        344334, 344342, 344344, 344346, 344355, 344374, 344376, 344421,
        344430, 344443, 344445, 344450..344826, 344851, 344876, 344890,
        344902, 344990, 344995, 344999..345000, 345033, 345101, 345111,
        345114, 345124, 345156..345157, 345176, 345203, 345209, 345225,
        345231, 345243, 345249, 345256, 345265, 345267, 345300, 345314,
        345345, 345379, 345388, 345411, 345418, 345429, 345434, 345444,
        345455..345456, 345492, 345512, 345522, 345534, 345554, 345556,
        345562, 345565, 345576, 345582, 345590, 345600, 345612, 345618,
        345621, 345623..345624, 345627..345628, 345633, 345643, 345645,
        345650, 345653, 345663, 345665..345668, 345672, 345674,
        345676..345678, 345687..345688, 345698..345699, 345704, 345723,
        345726, 345765, 345789, 345796, 345800, 345817..345818,
        345997..346114, 346180..347175, 347230..347499, 347750..347929, 348090,
        348234..348765, 348776..349999, 370000..370512, 370531..370807, 370813..379999
        'amex'
      when 180000..180099, 213100..213199, 310000, 334021, 352800..358999
        'jcb'
      when 400000..401177, 401180..431273, 431275..438934, 438936..451415,
        451417..457392, 457394..457630, 457633..499999
        'visa'
      when 500003..508406, 560017..561002, 561012, 561062, 561086, 561091..601094, 601200..601299, 601301..606099, 606101, 606106, 606122, 606144, 606163, 606172, 606179, 606257, 606263, 606269, 606274, 606287, 606295, 606299, 606305, 606325, 606329, 606335..606336, 606348, 606357, 606361, 606364..606365, 606372, 606379, 606384, 606401, 606404, 606410, 606441, 606450, 606452, 606457, 606469, 606484, 606801, 607180, 610093..620010, 620013..620026, 620030, 620035, 620048..620088, 620152..620153, 620218, 620518..620531, 621004..621010, 621014..621019, 621021, 621024, 621026, 621028..621030, 621033..621038, 621040..621050, 621053..621077, 621080..621217, 621221..621248, 621250..621427, 621517..621599, 621660..622125, 622433, 622927..622928, 622930..622933, 622935..622940, 622942..622943, 622945..622955, 622957, 622959..622963, 622967..622968, 622971..622980, 622982..622983, 622986, 622989..622998, 626257, 627066..627779, 627781..628182, 629441..631909, 633110, 633128, 633174..633675, 633698..636261, 636325..636366, 636392..636868, 637102..637529, 639000..642457, 663913, 666000..690755
        'intl maestro'
      when 222100..272099, 510000..554976, 554978..557005, 557008..557073, 557075..557078,
        557080..557082, 557084..557262, 557264..557293, 557295..557313, 557315..557317,
        557319, 557321..557324, 557330..557335, 557337..557338, 557340..557345,
        557347..557569, 557571..557572, 557574, 557576..557577, 557581..557590,
        557594, 557599..557604, 557606..557609, 557611..557639, 557641..557649,
        557652..557654, 557656..557658, 557660..557674, 557676..557697, 557700..557711,
        557713..559599, 559601..559643, 559648, 559650, 559652..559653, 559660,
        559662, 559668..559669, 559672..559679, 559681..559799, 559802,
        559808..559811, 559813..559816, 559822..559823, 559825, 559827..559828,
        559832, 559834, 559836, 559838, 559840..559848, 559850, 559852..559853,
        559855..559856, 559858..559861, 559863..559866, 559868, 559870..559876,
        559878..559883, 559885..559890, 559893, 559895..559999
        'master'
      when 561003..561004, 561006, 561009, 561013, 561018, 561021,
        561025, 561033..561034, 561038..561039, 561041, 561047,
        561059..561060, 561065..561066, 561069, 561072..561073,
        561076, 561078, 561080, 561084, 561090
        'australian bankcard'
      when 380000..384099, 384101..384139, 384141..384159, 384161..399999, 601100..601110,
        601120..601149, 601174, 601177..601179, 601186..601199, 601300, 644000..650030,
        650034, 650052..650404, 650440..650484, 650539..650540, 650599..650699, 650719,
        650728..650900, 650921..651651, 651680..652149, 652222, 652224, 652237..652238,
        652247..652399, 652401..652849, 652881..654102, 654104..654105, 654107..654110,
        654113..654114, 654118..654119, 654121..654122, 654124, 654126..654130,
        654134..654138, 654140..654149, 654151..654202, 654204..654205, 654207..654210,
        654213..654214, 654216..654219, 654221..654222, 654224, 654226..654230,
        654233..654238, 654240..654249, 654251..654999, 655020, 655059..655602,
        655604..655605, 655607..655610, 655613..655614, 655619, 655621..655622,
        655624, 655626..655630, 655634..655638, 655640..655649, 655651..655802,
        655804..655805, 655807..655810, 655813, 655819, 655821..655822, 655824,
        655826..655830, 655833..655838, 655840..655849, 655851..655915, 655917,
        655919, 655921..657015, 657017, 657019, 657021..657030, 657033..657038,
        657040..657302, 657304..657305, 657307..657310, 657319, 657321..657322,
        657324, 657326, 657328..657330, 657334..657338, 657340..657349, 657351..659999
        'discover'
      else
        'unknown'
    end
  end
end
