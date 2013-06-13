# Copyright 2013 by eMerchantPay. Author: Georgi Mitev (g.mitev@emerchantpay.com)
module ISO8583
  
  class FixedPositionSubfield
    attr_accessor :string_id
    attr_accessor :additional_info
    attr_accessor :mandatory
    attr_accessor :start_position
    attr_accessor :subfield_length
    attr_accessor :value2text
    

    def set_subfield( map_string_id2subfield, _start_position, _subfield_length, _string_id, _additional_info, _mandatory=true, _value2text = nil )
      @start_position = _start_position
      @subfield_length = _subfield_length
      @string_id = _string_id
      @additional_info = _additional_info
      @mandatory = _mandatory
      @value2text = _value2text

      map_string_id2subfield[ _string_id ] = self
    end

    def serialize( subfield_value )
      if( subfield_value.length != @subfield_length )
        raise ArgumentError.new "#{@string_id} subfield length mismatch. Found: #{subfield_value.length}, wanted: #{(@subfield_length)}. Value passed: #{subfield_value}"
      end
      subfield_value
    end

    def deserialize( result_map, raw_array )
      ISO8583::array_to_hashmap_fixed_len( result_map, @string_id, raw_array, 0, @subfield_length, @additional_info )
      
      ISO8583::add_value2text(result_map, @value2text, @string_id )
      @subfield_length
    end
  end

  class FixedSizeXXSubfield
    attr_accessor :numeric_id
    attr_accessor :string_id
    attr_accessor :additional_info
    attr_accessor :mandatory
    attr_accessor :fixed_size
    attr_accessor :value2text

    def set_subfield( map_numeric_id2subfield, map_string_id2subfield, _fixed_size, _numeric_id, _string_id, _additional_info, _mandatory, _value2text = nil )
      @fixed_size = _fixed_size
      @numeric_id = _numeric_id
      @string_id = _string_id
      @additional_info = _additional_info
      @mandatory = _mandatory
      @value2text = _value2text

      map_numeric_id2subfield[ _numeric_id ] = self
      map_string_id2subfield[ _string_id ] = self
    end

    def serialize( subfield_value )
      xx_value_to_array( subfield_value,  @fixed_size, @numeric_id, @string_id, @additional_info, @mandatory )
    end

    def deserialize( result_map, raw_array )
      ISO8583::array_to_hashmap_fixed_len( result_map, @string_id, raw_array, 0, @fixed_size, @additional_info )
      ISO8583::add_value2text(result_map, @value2text, @string_id )
      @fixed_size
    end
  end

  class LLLXXSubfield 
    attr_accessor :numeric_id
    attr_accessor :string_id
    attr_accessor :additional_info
    attr_accessor :mandatory
    attr_accessor :value2text

    def set_subfield( map_numeric_id2subfield, map_string_id2subfield, _numeric_id, _string_id, _additional_info, _mandatory, _value2text = nil )
      @numeric_id = _numeric_id
      @string_id = _string_id
      @additional_info = _additional_info
      @mandatory = _mandatory
      @value2text = _value2text

      map_numeric_id2subfield[ _numeric_id ] = self
      map_string_id2subfield[ _string_id ] = self
    end

    def serialize( subfield_value )
      field_id_dd = "%02d" % @numeric_id
      lll = "%03d" % (2 + subfield_value.length) # 2 is the length of field_id_dd
      
      lll + field_id_dd + subfield_value
    end

    def deserialize( result_map, raw_array )
      lll = raw_array[0,3]
      l = lll.to.i
      lll_rest = raw_array[3 .. raw_array.length]

      ISO8583::array_to_hashmap_fixed_len( result_map, @string_id, lll_rest, 0, l+2, @additional_info )
      ISO8583::add_value2text(result_map, @value2text, @string_id )
      l + 2 + 3
    end
  end
  
  class LLLXXFixedSizeSubfield < FixedSizeXXSubfield
    def serialize( subfield_value )
      lll = "%03d" % (@fixed_size + 2)
      field_id_dd = "%02d" % @numeric_id
      if( @fixed_size != subfield_value.length )
        raise ArgumentError.new "#{@string_id}subfield [#{@numeric_id}] length mismatch. Found: #{subfield_value.length}, wanted: #{(@fixed_size)}"
      end
      lll + field_id_dd + subfield_value
    end

    def deserialize( result_map, raw_array )
      lll = raw_array[0,3]
      l = lll.to_i
      lll_rest = raw_array[3 .. raw_array.length]

      if( l != (2+@fixed_size) )
        raise ArgumentError.new "#{@string_id}subfield [#{@numeric_id}] length mismatch. Found: #{l}, wanted: #{(2+@fixed_size)}"
      end

      ISO8583::array_to_hashmap_fixed_len( result_map, @string_id, lll_rest, 2, @fixed_size, @additional_info )
      ISO8583::add_value2text(result_map, @value2text, @string_id )
      @fixed_size + 3 + 2
    end
  end
end 