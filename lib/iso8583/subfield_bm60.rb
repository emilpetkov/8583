# Copyright 2013 by Georgi Mitev (g.mitev@emerchantpay.com)

module ISO8583

  ##############################################################################
    F60_Codec = Codec.new
    F60_Codec.encoder = lambda{ |params_hashtable, message|
#puts "params_hashtable = " + params_hashtable.map{|k,v| "#{k}='#{v}'"}.join(' & ')
      serialize_bm60_subfields(  params_hashtable, message )
    }
    F60_Codec.decoder = lambda {  |raw, message|
      deserialize_bm60_subfields(  raw, message )
    }
    
  ##############################################################################
  def self.serialize_bm60_subfields( params_hashtable, message )
    identified_subfields = 0
    field_raw_data = ""
    
    params_hashtable.each_pair do |subfield_string_id, subfield_value|
      encoded_subfield = case subfield_string_id # TODO
      when :cvv2_presence_indicator
        xx_value_to_array( subfield_value,  1, 30, :cvv2_presence_indicator, "", false );
      when :address_verification_data_request
        xx_value_to_array( subfield_value, 49, 31, :address_verification_data_request, "", false );
      when :address_verification_data_response
        xx_value_to_array( subfield_value,  2, 32, :address_verification_data_response, "", false );
      when :merchant_post_code
        xx_value_to_array( subfield_value, 10, 35, :merchant_post_code, "", false );
      when :dynamic_currency_conversion_data
        xx_value_to_array( subfield_value, 29, 37, :dynamic_currency_conversion_data, "", false );
      when :electronic_commerce_indicator
        xx_value_to_array( subfield_value,  2, 40, :electronic_commerce_indicator, "", false );
      when :recurring_payment_indicator
        xx_value_to_array( subfield_value,  1, 51, :recurring_payment_indicator, "", false );
      when :recurring_payment_response
        xx_value_to_array( subfield_value,  2, 52, :recurring_payment_response, "", false );
      when :terminal_capabilities
        xx_value_to_array( subfield_value,  3, 53, :terminal_capabilities, "", false );
      when :batch_information
        xx_value_to_array( subfield_value, 99, 54, :batch_information, "", false );
      when :additional_authorisation_data
        xx_value_to_array( subfield_value, 30, 55, :additional_authorisation_data, "", false );
      when :xid
        xx_value_to_array( subfield_value, 40, 61, :xid, "", false );
      when :cavv
        xx_value_to_array( subfield_value, 40, 62, :cavv, "", false );
      when :ucaf
        sli_pos3 = subfield_value[2,1]
        subfield_len = case sli_pos3
        when "0", "1"
          3
        when "2"
          35
        when "3"
          31
        else
          raise ArgumentError.new "BM 60 value subfield 63 has incorect/unknown SLI_pos3 value '#{sli_pos3}'"
        end
        xx_value_to_array( subfield_value, subfield_len, 63, :ucaf, "", false );
      when :mastercard_assigned_id
        xx_value_to_array( subfield_value,  6, 64, :mastercard_assigned_id, "", false );
      else
        raise ArgumentError.new "BM 60 value '#{raw}' has incorect/unknown subfield indicator #{subfield_string_id}"
      end
      
      identified_subfields += 1
      field_raw_data = field_raw_data + encoded_subfield
    end # params_hashtable.each_pair do
    
    if( identified_subfields != params_hashtable.length )
        raise ArgumentError.new "BM 60 arguments hashmap has unparsed elements. Identified subfields '#{identified_subfields}'. Elements in hashmap: #{params_hashtable.length}"
    end
    
    field_raw_data
  end
    
  ##############################################################################
  def self.deserialize_bm60_subfields( raw_src, message )
#    lll_str = raw_src[0,3]
#    lll = lll_str.to_i
#    
#    if( raw_src.length < lll )
#        raise ArgumentError.new "BM 60 value seems to  be longer than the rest message"
 
    result_hashmap = Hash.new
    index = 0
    while index != raw_src.length
      subfield_id = raw_src[index, 2].to_i
      index = case subfield_id
      when 30
        array_to_hashmap_fixed_len( result_hashmap, :cvv2_presence_indicator, raw_src, index+2, 1, "CVV2 Presence Indicator (Visa CNP Only) (SF\##{subfield_id})" )
      when 31
        array_to_hashmap_fixed_len( result_hashmap, :address_verification_data_request, raw_src, index+2, 49, "Address Verification Data, Request (SF\##{subfield_id})" )
      when 32
        array_to_hashmap_fixed_len( result_hashmap, :address_verification_data_response, raw_src, index+2, 2, "Address Verification Data, Response (SF\##{subfield_id})" )
      when 35
        array_to_hashmap_fixed_len( result_hashmap, :merchant_post_code, raw_src, index+2, 10, "Merchant Post Code (SF\##{subfield_id})" )
      when 37
        array_to_hashmap_fixed_len( result_hashmap, :dynamic_currency_conversion_data, raw_src, index+2, 29, "Dynamic Currency Conversion (DCC) Data (SF\##{subfield_id})" )
      when 40
        array_to_hashmap_fixed_len( result_hashmap, :electronic_commerce_indicator, raw_src, index+2, 2, "Electronic Commerce Indicator (ECI) (SF\##{subfield_id})" )
      when 51
        array_to_hashmap_fixed_len( result_hashmap, :recurring_payment_indicator, raw_src, index+2, 1, "Recurring Payment Indicator (SF\##{subfield_id})" )
      when 52
        array_to_hashmap_fixed_len( result_hashmap, :recurring_payment_response, raw_src, index+2, 2, "Recurring Payment Response (SF\##{subfield_id})" )
      when 53
        array_to_hashmap_fixed_len( result_hashmap, :terminal_capabilities, raw_src, index+2, 3, "Terminal Capabilities (SF\##{subfield_id})" )
      when 54
        array_to_hashmap_fixed_len( result_hashmap, :batch_information, raw_src, index+2, 99, "Batch Information (SF\##{subfield_id})" )
      when 55
        array_to_hashmap_fixed_len( result_hashmap, :additional_authorisation_data, raw_src, index+2, 30, "Additional Authorisation Data (SF\##{subfield_id})" )
      when 61
        array_to_hashmap_fixed_len( result_hashmap, :xid, raw_src, index+2, 40, "XID (SF\##{subfield_id})" )
      when 62
        array_to_hashmap_fixed_len( result_hashmap, :cavv, raw_src, index+2, 40, "CAVV (VISA Cardholder Authentication Verification Value  - CAVV – 3D Secure) (SF\##{subfield_id})" )
      when 63
        # position 3 of subfield 63 is key for the length of the subfield
        sli_pos3 = raw_src[(index + 2) + 3 - 1, 1]
        if( sli_pos3 == "2" )
            array_to_hashmap_fixed_len( result_hashmap, :ucaf, raw_src, index+2, 35, "This comprises of a security level indicator (SLI) and UCAF Data (SF\##{subfield_id}; sli_pos3 == 2, so len=35 )" )
        elsif( sli_pos3 == "3" )
            array_to_hashmap_fixed_len( result_hashmap, :ucaf, raw_src, index+2, 31, "This comprises of a security level indicator (SLI) and UCAF Data (SF\##{subfield_id}; sli_pos3 == 3, so len=31 )" )
        elsif( sli_pos3 == "1" || sli_pos3 == "0" )
            array_to_hashmap_fixed_len( result_hashmap, :ucaf, raw_src, index+2, 3, "This comprises of a security level indicator (SLI) and UCAF Data (SF\##{subfield_id}; sli_pos3 == 0 or 1, so len=3 )" )
        else
            raise ArgumentError.new "BM 60 value subfield 63 has incorect/unknown SLI_pos3 value '#{sli_pos3}'"
        end
      when 64
        array_to_hashmap_fixed_len( result_hashmap, :mastercard_assigned_id, raw_src, index+2, 6, "MasterCard Assigned ID (SF\##{subfield_id})" )
#      when ?
#        array_to_hashmap_fixed_len( result_hashmap, :, raw_src, index+2, , "??? (SF\##{subfield_id})" )
      else
        raise ArgumentError.new "BM 60 value has incorect/unknown subfield indicator #{raw_src[index, 2]}; All BM 60 data is '#{raw_src}'"
      end # case
    end # while
    
    result_hashmap
  end

end # Module