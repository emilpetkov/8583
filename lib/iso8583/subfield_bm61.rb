module ISO8583

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
end
