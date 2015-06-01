module ISO8583

  F44_visa_string_id2subfield = Hash.new

  FixedPositionSubfield.new.set_subfield(F44_visa_string_id2subfield,  0, 1, :visa_reason_code,            "BM 44, subfield :visa_reason_code", true, BM44::VISA_REASON_CODE_TRANSLATION)
  FixedPositionSubfield.new.set_subfield(F44_visa_string_id2subfield,  1, 1, :visa_avr_code,               "BM 44, subfield :visa_avr_code", false, BM44::VISA_AVR_CODE_TRANSLATION)
  FixedPositionSubfield.new.set_subfield(F44_visa_string_id2subfield,  2, 1, :visa_reserved3,              "BM 44, subfield :visa_reserved3", false, BM44::VISA_RESERVED3_TRANSLATION)
  FixedPositionSubfield.new.set_subfield(F44_visa_string_id2subfield,  3, 1, :visa_card_product_type,      "BM 44, subfield :visa_card_product_type", false, BM44::VISA_CARD_PRODUCT_TYPE_TRANSLATION)
  FixedPositionSubfield.new.set_subfield(F44_visa_string_id2subfield,  4, 1, :visa_cvv_result_code,        "BM 44, subfield :visa_cvv_result_code", false, BM44::VISA_CVV_RESULT_CODE_TRANSLATION)
  FixedPositionSubfield.new.set_subfield(F44_visa_string_id2subfield,  5, 2, :visa_pacm_diversion_level,   "BM 44, subfield :visa_pacm_diversion_level", false, BM44::VISA_PACM_DIVERSION_LEVEL_TRANSLATION)
  FixedPositionSubfield.new.set_subfield(F44_visa_string_id2subfield,  7, 1, :visa_pacm_reason_code,       "BM 44, subfield :visa_pacm_reason_code", false, BM44::VISA_PACM_REASON_CODE_TRANSLATION)
  FixedPositionSubfield.new.set_subfield(F44_visa_string_id2subfield,  8, 1, :visa_reserved8,              "BM 44, subfield :visa_reserved8", false, BM44::VISA_RESERVED8_TRANSLATION)
  FixedPositionSubfield.new.set_subfield(F44_visa_string_id2subfield,  9, 1, :visa_card_authentication_result_code, "BM 44, subfield :visa_card_authentication_result_code", false, BM44::VISA_CARD_AUTHENTICATION_RESULT_CODE_TRANSLATION)
  FixedPositionSubfield.new.set_subfield(F44_visa_string_id2subfield, 10, 1, :visa_cvv2_result_code,       "BM 44, subfield :visa_cvv2_result_code", false, BM44::VISA_CVV2_RESULT_CODE_TRANSLATION)
  FixedPositionSubfield.new.set_subfield(F44_visa_string_id2subfield, 11, 2, :visa_original_response_code, "BM 44, subfield :visa_original_response_code", false, BM44::VISA_ORIGINAL_RESPONSE_CODE_TRANSLATION)
  FixedPositionSubfield.new.set_subfield(F44_visa_string_id2subfield, 13, 1, :visa_check_settlment_code,   "BM 44, subfield :visa_check_settlment_code", false, BM44::VISA_CHECK_SETTLMENT_CODE_TRANSLATION)
  FixedPositionSubfield.new.set_subfield(F44_visa_string_id2subfield, 14, 1, :visa_cavv_result_code,       "BM 44, subfield :visa_cavv_result_code", false, BM44::VISA_CAVV_RESULT_CODE_TRANSLATION)
  FixedPositionSubfield.new.set_subfield(F44_visa_string_id2subfield, 15, 4, :visa_response_reason_code,   "BM 44, subfield :visa_response_reason_code", false, BM44::VISA_RESPONSE_REASON_CODE_TRANSLATION)

  F44_mastercard_string_id2subfield = Hash.new

  FixedPositionSubfield.new.set_subfield(F44_mastercard_string_id2subfield,  0,  1, :mastercard_result_code,          "BM 44, subfield :mastercard_result_code")
  FixedPositionSubfield.new.set_subfield(F44_mastercard_string_id2subfield,  1, 12, :mastercard_banknet_reference_id, "BM 44, subfield :mastercard_banknet_reference_id")
  FixedPositionSubfield.new.set_subfield(F44_mastercard_string_id2subfield, 13, 25, :mastercard_banknet_additional,   "BM 44, subfield :mastercard_banknet_reference_id")
  
  F44_Codec = Codec.new
  F44_Codec.encoder = lambda { |params_hashtable, message| serialize_bm44_subfields_new(params_hashtable, message) }
  F44_Codec.decoder = lambda { |raw, message| deserialize_bm44_subfields_new(raw, message) }
  
  def self.serialize_bm44_subfields_new(params_hashtable, message)
    card_brand = credit_card_brand(message[2]).downcase # field 2 is PAN

    case card_brand
    when 'master', 'Intl Maestro'
      # correct the variable length of the last element
      my_F44_mastercard_string_id2subfield = F44_mastercard_string_id2subfield.dup
      my_F44_mastercard_string_id2subfield[:mastercard_banknet_additional].subfield_length = params_hashtable[:mastercard_banknet_additional].length

      serialize_fixed_subfields(62, my_F44_mastercard_string_id2subfield, params_hashtable, message)
    when 'visa'
      serialize_fixed_subfields(62, F44_visa_string_id2subfield, params_hashtable, message)
    else
      error_message = "don't know how to decode BM 44 for card brand #{card_brand}, so leaving the other fields empty"
      puts error_message
      return 'card_brand unknown'
    end
  end

  def self.deserialize_bm44_subfields_new(raw, message)
    result_hash = Hash.new

    card_brand = credit_card_brand(message[2]).downcase # field 2 is PAN

    case card_brand
    when 'master', 'Intl Maestro'
      # correct the variable length of the last element
      my_F44_mastercard_string_id2subfield = F44_mastercard_string_id2subfield.dup

      # the length of the last (third) field (:mastercard_banknet_additional) is the rest of raw data: first field is 1 byte, the second is 12 bytes
      my_F44_mastercard_string_id2subfield[:mastercard_banknet_additional].subfield_length = raw.length - 12 - 1


      deserialize_fixed_subfields(44, my_F44_mastercard_string_id2subfield, raw, message)
    when 'visa'
      my_F44_visa_string_id2subfield = F44_visa_string_id2subfield.dup
      my_F44_visa_string_id2subfield = my_F44_visa_string_id2subfield.reject { |k,v| v.start_position >= raw.length }

      deserialize_fixed_subfields(44, my_F44_visa_string_id2subfield, raw, message)
    else
      error_message = "don't know how to decode BM 44 for card brand #{card_brand}, so leaving the other fields empty"
      puts error_message
      result_hash[:error] = error_message
      return result_hash
    end
  end
end
