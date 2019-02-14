module ISO8583

  VISA                       = 'visa'.freeze
  MASTER                     = 'master'.freeze
  MAESTRO                    = 'intl maestro'.freeze
  SUPPORTED_CARD_BRANDS      = [VISA, MASTER, MAESTRO].freeze
  VISA_FIXED_PARAMS_LENGTH   = 20.freeze
  MASTER_FIXED_PARAMS_LENGTH = 3.freeze

  # Omnipay specifics
  F61_string_id2subfield  = Hash.new
  F61_numeric_id2subfield = Hash.new

  LLLXXFixedSizeSubfield.new.set_subfield(F61_numeric_id2subfield, F61_string_id2subfield, 2,  18, :related_transaction_data,      'BM61: Related Transaction Data', false)
  LLLXXFixedSizeSubfield.new.set_subfield(F61_numeric_id2subfield, F61_string_id2subfield, 60, 41, :unique_transaction_identifier, 'BM61: Unique Transaction Identifier', false)
  LLLXXFixedSizeSubfield.new.set_subfield(F61_numeric_id2subfield, F61_string_id2subfield, 11, 61, :payment_facilitator_id,        'BM61: Payment Facilitator ID', false)
  LLLXXFixedSizeSubfield.new.set_subfield(F61_numeric_id2subfield, F61_string_id2subfield, 11, 62, :iso_id,                        'BM61: Independent Sales Organization ID', false)
  LLLXXFixedSizeSubfield.new.set_subfield(F61_numeric_id2subfield, F61_string_id2subfield, 15, 63, :sub_merchant_id,               'BM61: Sub-Merchant ID', false)

  F61_Codec = Codec.new
  F61_Codec.encoder = lambda { |params_hashtable, message| serialize_lllxx_subfields(61, F61_string_id2subfield, params_hashtable, message) }
  F61_Codec.decoder = lambda { |raw, message|              deserialize_lllxx_subfields(61, F61_numeric_id2subfield, raw, message) }

  # Paynetics Specifics
  BMP61_mastercard_string_id2subfield = Hash.new

  FixedPositionSubfield.new.set_subfield(BMP61_mastercard_string_id2subfield, 0,  3, :financial_network_code, 'BMP61: Financial Network Code ', false)
  FixedPositionSubfield.new.set_subfield(BMP61_mastercard_string_id2subfield, 3,  9, :banknet_reference,      'BMP61: BankNet Reference', false)

  BMP61_visa_string_id2subfield = Hash.new

  FixedPositionSubfield.new.set_subfield(BMP61_visa_string_id2subfield, 0, 15, :transaction_identifier,                  'BM61: Transaction Identifier', false)
  FixedPositionSubfield.new.set_subfield(BMP61_visa_string_id2subfield, 15, 4, :validation_code,                         'BM61: Validation Code', false)
  FixedPositionSubfield.new.set_subfield(BMP61_visa_string_id2subfield, 19, 1, :authorization_characteristics_indicator, 'BM61: Authorization Characteristics Indicator', false)
  FixedPositionSubfield.new.set_subfield(BMP61_visa_string_id2subfield, 20, 2, :card_level_results,                      'BM61: Card-Level Results', false)

  BMP61_Codec = Codec.new
  BMP61_Codec.encoder = lambda { |params_hashtable, message| serialize_bmp61_subfields(params_hashtable, message) }
  BMP61_Codec.decoder = lambda { |raw_params, message|       deserialize_bmp61_subfields(raw_params, message)     }

  def self.serialize_bmp61_subfields(params_hashtable, message)
    card_brand = credit_card_brand(message[2]).downcase # field 2 is PAN

    return log_unknown_card_brand_for(card_brand, true) unless SUPPORTED_CARD_BRANDS.include?(card_brand)

    params_hashtable_serialized = params_hashtable.deep_dup
    params_hashtable_serialized.each { |key, value| params_hashtable_serialized[key] = EBCDIC_Codec.encode(value) }
    if card_brand == VISA
      BMP61_visa_string_id2subfield[:card_level_results].subfield_length = params_hashtable_serialized[:card_level_results].length if params_hashtable_serialized[:card_level_results]
      serialize_fixed_subfields(61, BMP61_visa_string_id2subfield, params_hashtable_serialized, message)
    else
      BMP61_mastercard_string_id2subfield[:banknet_reference].subfield_length = params_hashtable_serialized[:banknet_reference].length
      serialize_fixed_subfields(61, BMP61_mastercard_string_id2subfield, params_hashtable_serialized, message)
    end
  end

  def self.deserialize_bmp61_subfields(raw_params, message)
    decoded_params = EBCDIC_Codec.decode(raw_params)
    card_brand     = credit_card_brand(message[2]).downcase # field 2 is PAN

    return log_unknown_card_brand_for(card_brand) unless SUPPORTED_CARD_BRANDS.include?(card_brand)

    if card_brand == VISA
      BMP61_visa_string_id2subfield[:card_level_results].subfield_length = decoded_params.length - VISA_FIXED_PARAMS_LENGTH
      deserialize_fixed_subfields(61, BMP61_visa_string_id2subfield, decoded_params, message)
    else
      BMP61_mastercard_string_id2subfield[:banknet_reference].subfield_length = decoded_params.length - MASTER_FIXED_PARAMS_LENGTH
      deserialize_fixed_subfields(61, BMP61_mastercard_string_id2subfield, decoded_params, message)
    end
  end

  def self.log_unknown_card_brand_for(card_brand, message_only = false)
    error_message = "don't know how to decode BMP61 for card brand #{card_brand}, so leaving the other fields empty"
    p error_message

    return 'card_brand unknown' if message_only

    { error: error_message }
  end
end

