module ISO8583

  F62_string_id2subfield  = Hash.new
  F62_numeric_id2subfield = Hash.new
  
  LLLXXFixedSizeSubfield.new.set_subfield(F62_numeric_id2subfield, F62_string_id2subfield, 1,  1, :authorisation_characteristic_indicator, 'BM 62: Authorisation Characteristic Indicator', false)
  LLLXXFixedSizeSubfield.new.set_subfield(F62_numeric_id2subfield, F62_string_id2subfield, 15, 2, :transaction_identifier, 'BM 62: Transaction Identifier', false)
  LLLXXFixedSizeSubfield.new.set_subfield(F62_numeric_id2subfield, F62_string_id2subfield, 4,  3, :validation_code, 'BM 62: Validation Code', false)
  LLLXXFixedSizeSubfield.new.set_subfield(F62_numeric_id2subfield, F62_string_id2subfield, 1,  4, :market_specific_data_identified, 'BM 62: Market Specific Data Identified', false)
  LLLXXFixedSizeSubfield.new.set_subfield(F62_numeric_id2subfield, F62_string_id2subfield, 2,  5, :duration, 'BM 62: Duration', false)
  LLLXXFixedSizeSubfield.new.set_subfield(F62_numeric_id2subfield, F62_string_id2subfield, 1,  6, :prestigious_property_indicator, 'BM 62: Prestigious Property Indicator', false)
  LLLXXFixedSizeSubfield.new.set_subfield(F62_numeric_id2subfield, F62_string_id2subfield, 2, 23, :card_level_results, 'BM 62: Card Level Results', false)
  LLLXXFixedSizeSubfield.new.set_subfield(F62_numeric_id2subfield, F62_string_id2subfield, 1, 25, :spend_qualified_indicator, 'BM 62: Spend Qualified Indicator', false)
  LLLXXFixedSizeSubfield.new.set_subfield(F62_numeric_id2subfield, F62_string_id2subfield, 1, 26, :account_status_for_tokenization, 'BM 62: Account Status for Tokenization', false)

  F62_Codec = Codec.new
  F62_Codec.encoder = lambda { |params_hashtable, message| serialize_lllxx_subfields(62, F62_string_id2subfield, params_hashtable, message) }
  F62_Codec.decoder = lambda { |raw, message| deserialize_lllxx_subfields(62, F62_numeric_id2subfield, raw, message) }
end
