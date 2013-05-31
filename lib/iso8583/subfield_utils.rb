# Copyright 2013 by Georgi Mitev (g.mitev@emerchantpay.com)

module ISO8583
  ##############################################################################
  def self.array_to_hashmap_fixed_len( hashmap, hashmap_id, raw_array, start_pos, data_len, field_info )
    if( raw_array.length < (start_pos + data_len) )
      raise ArgumentError.new field_info + ": No space in raw array to src value, arr_len=#{raw_array.length}, data_end_pos=#{start_pos + data_len}"
    end

    hashmap[ hashmap_id ] = raw_array[ start_pos .. (start_pos+data_len-1) ]    
    
    start_pos + data_len
  end
  
  ##############################################################################
  def self.value_to_array( src, raw_array, start_pos, data_len, field_info, mandatory )
    if( raw_array.length < (start_pos + data_len) )
      raise ArgumentError.new field_info + ": No space in raw array to src value, arr_len=#{raw_array.length}, data_end_pos=#{start_pos + data_len}"
    end
    
    if( (not src) || src.length < 1 )
      if( mandatory )
        raise ArgumentError.new field_info + ": mandatory field is not filled"
      else
        # just skipping
        return
      end
    end
    
    if( src.length != data_len )
        raise ArgumentError.new field_info + ": src_field_length=#{src.length}; dst_field_length=#{data_len}; src='#{src}'"
    end
    
    raw_array[ start_pos .. (start_pos+data_len-1) ] = src
  end
  
  def self.xx_value_to_array( raw_array, data_len, subfield_num_id1, subfield_str_id1, field_info1, mandatory )
    if( (not raw_array) && (not mandatory) )
      return ""
    end
    
    if( subfield_num_id1 < 0 || subfield_num_id1 > 99 )
      raise ArgumentError.new "#{field_info1} (subfield_id=#{subfield_num_id1}/#{subfield_str_id1}): subfield_id is not in range 00-99"
    end
    
    subfield_id2 = (subfield_num_id1 < 10 ? "0" : "") + subfield_num_id1.to_s
    
    field_info2 = (field_info2 ? field_info2 + " " : "") + "(subfield_id=#{subfield_num_id1}/#{subfield_str_id1})";
    
    if data_len != raw_array.length
      raise ArgumentError.new "#{field_info1} (subfield_id=#{subfield_num_id1}/#{subfield_str_id1}): provided data length(#{raw_array.length}) differs from required length(#{data_len})"
    end
    
    subfield_id2 + raw_array
#    value_to_array( subfield_id2 + src, raw_array, start_pos, data_len + 2, field_info2, mandatory )
  end
  ##############################################################################
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
        'mastercard'
      when 5610
        'australian bankcard'
      when 6011
        'discover'
      else
        'unknown'
    end
  end
  
end # module