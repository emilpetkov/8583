module ISO8583

  VISA    = 'visa'.freeze
  MASTER  = 'master'.freeze
  MAESTRO = 'intl maestro'.freeze

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

  def self.serialize_bmp61_subfields(params_hashtable, message = nil)
    card_brand     = credit_card_brand(message[2]).downcase # field 2 is PAN

    case card_brand
    when VISA
      BMP61_visa_string_id2subfield[:card_level_results].subfield_length = params_hashtable[:card_level_results].length
      serialize_fixed_subfields(61, BMP61_visa_string_id2subfield, params_hashtable, message)
    when MASTER, MAESTRO
      BMP61_mastercard_string_id2subfield[:banknet_reference].subfield_length = params_hashtable[:banknet_reference].length
      serialize_fixed_subfields(61, BMP61_mastercard_string_id2subfield, params_hashtable, message)
    else
      error_message = "don't know how to decode BMP61 for card brand #{card_brand}, so leaving the other fields empty"
      puts error_message
      return 'card_brand unknown'
    end
  end

  def self.deserialize_bmp61_subfields(raw_params, message = nil)
    decoded_params = EBCDIC_Codec.decode(raw_params)
    card_brand     = credit_card_brand(message[2]).downcase # field 2 is PAN

    case card_brand
    when VISA
      BMP61_visa_string_id2subfield[:card_level_results].subfield_length = decoded_params.length - 20
      deserialize_fixed_subfields(61, BMP61_visa_string_id2subfield, decoded_params, message)
    when MASTER, MAESTRO
      BMP61_mastercard_string_id2subfield[:banknet_reference].subfield_length = decoded_params.length - 3
      deserialize_fixed_subfields(61, BMP61_mastercard_string_id2subfield, decoded_params, message)
    else
      result_hash = Hash.new
      result_hash[:error] = "don't know how to decode BMP61 for card brand #{card_brand}, so leaving the other fields empty"
      puts result_hash[:error]
      return result_hash
    end
  end
end

