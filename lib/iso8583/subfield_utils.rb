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
      when 300000..305999, 309500..309599, 360000..361093, 361219..361228, 361232, 361235..361259,
        361261..361269, 361271..361273, 361295..361298, 361300..361320, 361322, 361324..361346,
        361349..361423, 361430..361449, 361474..361475, 361477..361480, 361482..361489, 361558,
        361600..361899, 361991..361999, 362050..362053, 362056, 362058..362063, 362065..362138,
        362141, 362191..362196, 362200..362309, 362312, 362331..362339, 362343, 362345, 362347,
        362352..362365, 362368..362377, 362383..362385, 362392..362396, 362402..362405,
        362500..362503, 362509..362518, 362524..362530, 362535..362537, 362543..362553,
        362555..362560, 362563, 362600..362601, 362611..362614, 362620..362622, 362627..362634,
        363000, 363300..363599, 363999..364003, 364006..364060, 364062..364064, 364067..364070,
        364072..364090, 364093..364199, 364201..364205, 364211..364214, 364216..364219,
        364222..364224, 364226..364232, 364234..364267, 364269..364285, 364287..364412,
        364414..364436, 364441..364445, 364447..364465, 364467, 364470..364480, 364482..364483,
        364485..364489, 364491, 364493..364500, 364502, 364504..364514, 364516..364518,
        364521..364525, 364527..364547, 364560..364564, 364568..364569, 364571..364588,
        364590..364595, 364598, 364601..364606, 364610, 364612..364620, 364630, 364632..364639,
        364660..364667, 364671..364673, 364680..364689, 364700..364706, 364708, 364710..364726,
        364730..364759, 364770..364772, 364776..364795, 364797..364799, 364810..364812,
        364814..364816, 364821..364823, 364825..364830, 364836..364871, 364873, 364875..364878,
        364880, 364882..364884, 364886..364888, 364900..364901, 364910, 365001..365023,
        365025..365048, 365120..365129, 365132..365158, 365162..365164, 365166..365183,
        365185..365191, 365197..365206, 365217..365219, 365221, 365228..365230, 365251..365256,
        365298..365299, 365350..365394, 365400..365415, 365420..365429, 365431..365432, 365450,
        365452..365475, 365477..365488, 365494, 365502..365523, 365525..365530, 365532,
        365534..365535, 365537..365539, 365542, 365560..365574, 365588..365593, 365595..365603,
        365617..365619, 365628..365632, 365636, 365645..365646, 365649, 365700..365702,
        366000..366499, 366510..366629, 366762, 367000..367099, 369000..369146, 369148..369149,
        369160..369199, 369210..369215, 369400..369599, 369610, 369613..369614, 369616..369618,
        369810..369999
        'diners'
      when 324000, 337912..337913, 337941, 340000..344388, 344421, 344430, 344443, 344445,
        344450..344826, 344851, 344876, 344890, 344902, 344990, 344995, 344999..345000, 345033,
        345101, 345111, 345114, 345124, 345156..345157, 345176, 345203, 345209, 345225, 345231,
        345243, 345249, 345256, 345265, 345267, 345300, 345314, 345345, 345379, 345388, 345411,
        345418, 345429, 345434, 345444, 345455..345456, 345492, 345512, 345522, 345534, 345554,
        345556, 345562, 345565, 345576, 345582, 345590, 345600, 345612, 345618, 345621,
        345623..345624, 345627..345628, 345633, 345643, 345645, 345650, 345653, 345663,
        345665..345668, 345672, 345674, 345676..345678, 345687..345688, 345698..345699, 345704,
        345723, 345726, 345765, 345789, 345796, 345799..345978, 345997..346114, 346180..347175,
        347230..347499, 347508..347982, 348090, 348234..348765, 348776..349999, 370000..370512,
        370531..370807, 370813..379999
        'amex'
      when 180000..180099, 213100..213199, 310000, 334021, 352800..358999, 359073, 359089, 359169,
        359204, 359216, 359225, 359237, 359256, 359284, 359293, 359299, 359348, 359372,
        359500..359501, 359503, 359507, 359516, 359583, 359587, 359589, 359595, 359614, 359663,
        359770, 359772, 359801, 359854, 359883, 359899..359900, 359904, 359914, 359918, 359951,
        359980, 359984, 359988, 359996, 359999
        'jcb'
      when 400000..401177, 401180..420312, 420314..420353, 420355..420356, 420358..420404, 420408,
        420411, 420413..420416, 420419..420423, 420425..420427, 420429..420432, 420434, 420436,
        420439..420441, 420443..420444, 420446..420453, 420455..420460, 420463, 420467..420468,
        420470, 420472..420473, 420476..420479, 420481, 420484..420487, 420489..420505, 420508,
        420510..420543, 420545..420560, 420562..420799, 420801..420802, 420807..420809,
        420813..420814, 420818..420819, 420822, 420825, 420830..420831, 420836, 420838, 420840,
        420845, 420848, 420850..420851, 420855..420858, 420860..420862, 420864..420867,
        420870..420872, 420875..420876, 420880, 420884..420885, 420889, 420894, 420897,
        420899..431273, 431275..438934, 438936..451415, 451417..457392, 457394..457630,
        457633..465797, 465801..465802, 465805..465819, 465824..465950, 465953..465965,
        465967..465969, 465972, 465975..465998, 466001..466020, 466029..466032, 466035..466288,
        466293..466296, 466300..466400, 466492..466687, 466700..466706, 466708..466711,
        466715..466716, 466719..466727, 466730..466731, 466800..466809, 466920..466921, 466940,
        466950..466951, 466990, 467000..467003, 467005..467029, 467034, 467039, 467050..467059,
        467062..467064, 467067..467069, 467077, 467080..467089, 467092..467115, 467117, 467119,
        467124..467126, 467129..467131, 467134, 467139..467154, 467156..467176, 467178..467179,
        467188..467215, 467250..467262, 467264..467291, 467293..467409, 467425..468332, 468386,
        468400..468401, 468403, 468405..468406, 468408..468414, 468418..468419, 468421..468424,
        468426..470999, 471001, 471005, 471011, 471013, 471015..471016, 471019, 471023,
        471025..471029, 471032, 471036..471037, 471039, 471042, 471050, 471055, 471058, 471061,
        471068, 471073, 471079, 471083, 471090, 471095..471096, 471100..474918, 475000..475013,
        475015..475019, 475021..475027, 475029..475295, 475391..475947, 475993..476298,
        476300..476320, 476323..476327, 476329..476336, 476338..476389, 476396..476445,
        476447..476450, 476452..476457, 476459..476467, 476470..477679, 477700..477702, 477704,
        477706..477710, 477712..477728, 477730..477733, 477735..477753, 477755..477769,
        477771..477783, 477785..477815, 477817..477820, 477822..477823, 477825..477835,
        477837..477850, 477852..477859, 477864..478001, 478003, 478043..478097, 478172, 478188,
        478200..478203, 478205..478232, 478234..478244, 478246..478251, 478253..478899,
        478901..478903, 478905..478917, 478919..478920, 478922..478927, 478929..478932,
        478944..478954, 478956..478983, 478985..478990, 478992..478993, 478995, 478997..479499,
        479511, 479513, 479515..479529, 479550, 479595..480893, 480900..480999, 481100..481103,
        481109..481129, 481135..481144, 481146..481151, 481162..481176, 481187..481200,
        481221..481222, 481233..481299, 481331..481332, 481360, 481378..481388, 481438..481885,
        481890..485051, 485072..485208, 485210..485219, 485221, 485223..485226, 485228..485233,
        485235..485237, 485240, 485242..485250, 485252..485254, 485256..485261, 485270..485271,
        485273..485284, 485286..485307, 485310..485322, 485324..485328, 485330..485332,
        485334..485345, 485348..485523, 485560..485565, 485567, 485569..485611, 485619..485622,
        485624..485631, 485633..485634, 485637..485638, 485640..485649, 485651..485673,
        485700..485708, 485710..485713, 485715..485731, 485738, 485740..485744, 485747..485753,
        485764..485767, 485772, 485774, 485776, 485778..485781, 485783..485788, 485801..485809,
        485900..485906, 485909..485912, 485915, 485919..485943, 485945..485961, 485966..496159,
        496500..498099, 498300..498331, 498400..499004, 499010..499453, 499587..499999
        'visa'
      when 500003..501898, 502000..504157, 504188..506122, 507187..507857, 508100..508406,
        560017..561002, 561012, 561056, 561059, 561062, 561086, 561091..599032, 599113, 599900,
        600206..601094, 601200..602968, 602970..603358, 603395..603599, 603607..603693, 603696,
        603704, 603712..606070, 606072..606099, 606101, 606106, 606122, 606144, 606163, 606172,
        606179, 606257, 606263, 606269, 606274, 606287, 606295, 606299, 606305, 606325, 606329,
        606335..606336, 606348, 606357, 606361, 606364..606365, 606372, 606379, 606384, 606401,
        606404, 606410, 606441, 606450, 606452, 606457, 606469, 606484, 606801, 610093, 610098,
        610192, 610423..610424, 610434, 610460, 610470, 610522, 610559, 614483, 614552, 616788,
        618430..618439, 620009, 621019, 621055..621056, 621059, 621092, 621241, 621250, 621260,
        621289, 621326, 621338, 621346..621347, 621356, 621427, 621830..621976, 621984..622125,
        622433, 622927..622928, 622930..622933, 622935..622940, 622942..622943, 622945..622953,
        622955, 622957, 622959..622963, 622967..622968, 622971..622980, 622982..622983, 622986,
        622989..622998, 626257, 627089..627385, 627391..627779, 627781..628182, 629441..631909,
        633110, 633128, 633174..633675, 633698..636261, 636325, 636346, 636366, 636392..636868,
        637102, 637118, 637187, 637529, 639000..642491, 663913..681853, 689099, 690149, 990015
        'intl maestro'
      when 222100..272099, 510000..554976, 554978..557005, 557008..557073, 557075..557078,
        557080..557082, 557084..557262, 557264..557293, 557295..557313, 557315..557317, 557319,
        557321..557324, 557330..557335, 557337..557338, 557340..557345, 557347..557569,
        557571..557572, 557574, 557576..557577, 557581..557590, 557594, 557599..557604,
        557606..557609, 557611..557639, 557641..557649, 557652..557654, 557656..557658,
        557660..557674, 557676..557697, 557700..557711, 557713..559599, 559601..559643, 559648,
        559650, 559652..559653, 559660, 559662, 559668..559669, 559672..559679, 559681..559799,
        559802, 559808..559811, 559813..559816, 559822..559823, 559825, 559827..559828, 559832,
        559834, 559836, 559838, 559840..559848, 559850, 559852..559853, 559855..559856,
        559858..559861, 559863..559866, 559868, 559870..559876, 559878..559883, 559885..559890,
        559893, 559895..559999
        'master'
      when 561003..561004, 561006, 561009, 561013, 561018, 561021, 561025, 561033..561034,
        561038..561039, 561041, 561047, 561060, 561065..561066, 561069, 561072..561073, 561076,
        561078, 561080, 561084, 561090
        'australian bankcard'
      when 380000..384099, 384101..384139, 384141..384159, 384161..399999, 601100..601110,
        601120..601149, 601174, 601177, 601179, 601187..601195, 601197..601199, 601300,
        644000..649999, 650002..650030, 650034, 650052..650118, 650120..650404, 650440..650484,
        650539..650540, 650599..650699, 650719, 650728..650900, 650979..651651, 651680..652149,
        653150..654102, 654104..654105, 654107..654110, 654113..654114, 654118..654119,
        654121..654122, 654124, 654126..654130, 654134..654138, 654140..654149, 654151..654202,
        654204..654205, 654207..654210, 654213..654214, 654216..654219, 654221..654222, 654224,
        654226..654230, 654233..654238, 654240..654249, 654251..654999, 655020, 655059..655602,
        655604..655605, 655607..655610, 655613..655614, 655619, 655621..655622, 655624,
        655626..655630, 655634..655638, 655640..655649, 655651..655802, 655804..655805,
        655807..655810, 655813, 655819, 655821..655822, 655824, 655826..655830, 655833..655838,
        655840..655849, 655851..655915, 655917, 655919, 655921..655999, 656638, 656999..657015,
        657017, 657019, 657021..657030, 657033..657038, 657040..657299, 657301..657302,
        657304..657305, 657307..657310, 657319, 657321..657322, 657324, 657326, 657328..657330,
        657334..657338, 657340..657349, 657351..657358, 657360..659999
        'discover'
      else
        'unknown'
    end
  end
end
