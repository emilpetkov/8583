# Copyright 2013 by Georgi Mitev (g.mitev@emerchantpay.com)

module ISO8583

  ##############################################################################
    F44_Codec = Codec.new
    F44_Codec.encoder = lambda{ |params_hashtable, message|
#puts "params_hashtable = " + params_hashtable.map{|k,v| "#{k}='#{v}'"}.join(' & ')
      serialize_bm44_subfields(  params_hashtable, message )
    }
    F44_Codec.decoder = lambda {  |raw, message|
      deserialize_bm44_subfields(  raw, message )
    }
    
  ##############################################################################
  def self.serialize_bm44_subfields( params_hashtable, message )
  #    raise ISO8583Exception.new("Invalid value: #{str} must be [\x20-\x7E]") unless str =~ /^[\x20-\x7E]*$/
  #    str
      card_brand = credit_card_brand( message[2] ).downcase() # field 2 is PAN

      if( card_brand != "visa" && card_brand != "mastercard" )
        error_message = "we dont know how to decode BM 44 for card brand #{card_brand}, so leaving the other fields empty"
        puts error_message
        result_hash[ :error ] = error_message
        return result_hash
      end
      if( card_brand == "mastercard" )
        identified_params = 0
        # :result_code
        result_code = params_hashtable[ :result_code ]
        if( not result_code )
          raise ArgumentError.new "mastercard BM 44 value subfiled1 aka :result_code is mandatory to be set in the hashtable"
        end
        if( result_code.length != 1 )
          raise ArgumentError.new "mastercard BM 44 value subfiled1 aka :result_code must be one char"
        end
        result = result_code
        identified_params += 1
        
        # :mastercard_banknet_reference_id
        mastercard_banknet_reference_id = params_hashtable[ :mastercard_banknet_reference_id ]
        if( not mastercard_banknet_reference_id )
          raise ArgumentError.new "mastercard BM 44 value subfiled2 aka :mastercard_banknet_reference_id is mandatory to be set in the hashtable"
        end
        if( mastercard_banknet_reference_id.length != 12 )
          raise ArgumentError.new "mastercard BM 44 value subfiled2 aka :mastercard_banknet_reference_id must be 12 chars"
        end
        result = result + mastercard_banknet_reference_id
        identified_params += 1
        
        # mastercard_banknet_additional
        mastercard_banknet_additional = params_hashtable[ :mastercard_banknet_additional ]
        if( mastercard_banknet_additional )
          if( mastercard_banknet_additional.length > 25 )
            raise ArgumentError.new "mastercard BM 44 value subfiled3 aka :mastercard_banknet_additional must NOT be more than 25 chars"
          end
          result = result + mastercard_banknet_additional
          identified_params += 1
        end
        
        if( params_hashtable.length != identified_params )
          raise ArgumentError.new "mastercard BM 44: not all arguments in params hashtable are distinguished. All are #{params_hashtable.length}, while identified are #{identified_params}"
        end  
          
        return result
      end
    
      if( card_brand == "visa" )
        result = "                          " # 26 chars
        
#puts "params_hashtable = " + params_hashtable.map{|k,v| "#{k}='#{v}'"}.join(' & ')

        value_to_array( params_hashtable[ :visa_reason_code ],            result,  0, 1, "BM 44, subfield :visa_reason_code", true )
        value_to_array( params_hashtable[ :visa_avr_code ],               result,  1, 1, "BM 44, subfield :visa_avr_code", false )
        value_to_array( params_hashtable[ :visa_reserved3] ,              result,  2, 1, "BM 44, subfield :visa_reserved3", false )
        value_to_array( params_hashtable[ :visa_card_product_type ],      result,  3, 1, "BM 44, subfield :visa_card_product_type", false )
        value_to_array( params_hashtable[ :visa_cvv_result_code ],        result,  4, 1, "BM 44, subfield :visa_cvv_result_code", false )
        value_to_array( params_hashtable[ :visa_pacm_diversion_level ],   result,  5, 2, "BM 44, subfield :visa_pacm_diversion_level", false )
        value_to_array( params_hashtable[ :visa_pacm_reason_code ],       result,  7, 1, "BM 44, subfield :visa_pacm_reason_code", false )
        value_to_array( params_hashtable[ :visa_reserved10] ,             result,  8, 1, "BM 44, subfield :visa_reserved3", false )
        value_to_array( params_hashtable[ :visa_card_authentication_result_code ], result, 9, 1, "BM 44, subfield :visa_card_authentication_result_code", false )
        value_to_array( params_hashtable[ :visa_cvv2_result_code ],       result, 10, 1, "BM 44, subfield :visa_cvv2_result_code", false )
        value_to_array( params_hashtable[ :visa_original_response_code ], result, 11, 2, "BM 44, subfield :visa_original_response_code", false )
        value_to_array( params_hashtable[ :visa_check_settlment_code ],   result, 13, 1, "BM 44, subfield :visa_check_settlment_code", false )
        value_to_array( params_hashtable[ :visa_cavv_result_code ],       result, 14, 1, "BM 44, subfield :visa_cavv_result_code", false )
        value_to_array( params_hashtable[ :visa_response_reason_code ],   result, 15, 4, "BM 44, subfield :visa_response_reason_code", false )

        return result
      end
    
  end
    
  ##############################################################################
  def self.deserialize_bm44_subfields( raw, message )
    result_hash = Hash.new
    result_hash[ :card_brand ] = card_brand = credit_card_brand( message[2] ).downcase() # field 2 is PAN
    
    if( card_brand != "visa" && card_brand != "mastercard" )
      error_message = "we dont know how to decode BM 44 for card brand #{card_brand}, so leaving the other fields empty"
      puts error_message
      result_hash[ :error ] = error_message
      return result_hash
    end
    
    if( result_hash[ :card_brand ] == "mastercard" )
      if( raw.length < (1+12) )
        raise ArgumentError.new "BM 44 value '#{raw}' has incorect value. Format is subfield1 (fixed len 1 byte), subfield2 (fixed len 12 bytes), subfield3 (VAR...25: 2 bytes length prefix + the real content). Minimal length in this case is 1+13, but given string has length #{raw.length} bytes"
      end
      result_code = raw[0,1]
      result_hash[ :mastercard_result_code ] = result_code
      
      result_hash[ :mastercard_result_code_text ] = case result_code
      when "M" then
            "CVC2 match"
      when "N" then
            "CVC2 no match"
      when "P" then
            "Not Processed"
      when "U" then
            "Issuer is not certified"
      when "Y" then
            "CVC1 Incorrect"
      else
        raise ArgumentError.new "BM 44 value '#{raw}' has incorect value on the first character, pos 0. It may be incorrect for MasterCard onlu"
      end # case
      
      result_hash[ :mastercard_banknet_reference_id ] = raw[1,12]
      
      result_hash[ :mastercard_banknet_additional ]   = raw[13, raw.length - 13] # could be empty string also
    end

    if( result_hash[ :card_brand ] == "visa" )
      puts "VISA detected..\n\n\n\n\n\n"
=begin
          Subfields:
      44.1 Response Source/Reason Code (Position 1)
      44.2 Address Verification Result Code (Position2 )
      44.3 Reserved (Position 3)
      44.4 Card Product Type (Position 4)
      44.5 CVV/iCVV Results Code (Position 5 )
      44.6 PACM Diversion Level(Position 6-7 )
      44.7 PACM Diversion Reason Code (Position 8)
      44.8 Card Authentication Results Code (Position 9)
      44.9 Reserved (Position 10)
      44.10 CVV2 Result Code (Position 11)
      44.11 Original Response Code (Position 12-13)
      44.12 Check Settlement Code (U.S. only) (Position 14)
      44.13 CAVV Results Code (Position 15)
      44.14 Response Reason Code (Position 16-19)
=end

      reason_code = raw[0,1]

      result_hash[ :visa_reason_code ] = reason_code
      
      result_hash[ :visa_reason_code_text ] = case reason_code
      when "0" then
            "Advice of Exception File change"
      when "1" then
            "Response provided by STIP because the request was timed out by Switch"
      when "2" then
            "Response provided by STIP because the transaction amount was below issuer limit"
      when "3" then
            "Response provided by STIP because the issuer is in Suppress Inquiries mode"
      when "4" then
            "Response provided by STIP because issuer not available"
      when "5" then
            "Response provided by issuer"
      when "6" then
            "Enhanced STIP reason code provided on behalf of third-party processor"
      when "7" then
            "Reversal advice provided by VISA to identify a potential duplicate transaction"
      when "8" then
            "Reversal advice provided by VISA to identify a probable duplicate authorization"
      when "9" then
            "Enhanced STIP reason code provided by the VISA International Automated Referral Service"
      when "A" then
            "Response provided by a third-party authorizing agent (POS Check)"
      when " " then
            "Field not used – Fill for subsequent positions that are present"
      else
        raise ArgumentError.new "BM 44 value '#{raw}' has incorect value on the first character, pos 0. It may be illegal for Visa only..."
      end # case
      
      if( [6, 12, 16, 17, 18 ].include? raw.length)
        raise ArgumentError.new "BM 44 value '#{raw}' has incorect value. Some of the subfields is divided in the middle"
      end

      if raw.length > 1
        result_hash[ :visa_avr_code ] = raw[1,1]
      end
      if raw.length > 2
        result_hash[ :visa_reserved3 ] = raw[2,1]
      end
      if raw.length > 3
        result_hash[ :visa_card_product_type ] = raw[3,1]
      end
      if raw.length > 4
        result_hash[ :visa_cvv_result_code ] = raw[4,1]
      end
      if raw.length > 6
        result_hash[ :visa_pacm_diversion_level ] = raw[5,2]
      end
      if raw.length > 7
        result_hash[ :visa_pacm_reason_code ] = raw[7,1]
      end
      if raw.length > 9
        result_hash[ :visa_card_authentication_result_code ] = raw[9,1]
      end
      if raw.length > 10
        result_hash[ :visa_cvv2_result_code ] = raw[10,1]
      end
      if raw.length > 11
        result_hash[ :visa_original_response_code ] = raw[11,2]
      end
      if raw.length > 13
        result_hash[ :visa_check_settlment_code ] = raw[13,1]
      end
      if raw.length > 14
        result_hash[ :visa_cavv_result_code ] = raw[14,1]
      end
      if raw.length > 18
        result_hash[ :visa_response_reason_code ] = raw[15,4]
      end
    end # if visa

    result_hash
  end

end # Module