# Copyright 2013 by eMerchantPay. Author: Georgi Mitev (g.mitev@emerchantpay.com)

module ISO8583
  


  F62_string_id2subfield = Hash.new
  
  FixedPositionSubfield.new.set_subfield( F62_string_id2subfield, 0,  1, :authorisation_characteristic_indicator, "BM 62: Authorisation Characteristic Indicator" )
  FixedPositionSubfield.new.set_subfield( F62_string_id2subfield, 1, 15, :transaction_identifier, "BM 62: Transaction Identifier" )
  FixedPositionSubfield.new.set_subfield( F62_string_id2subfield, 16, 4, :validation_code, "BM 62: Validation Code" )
  FixedPositionSubfield.new.set_subfield( F62_string_id2subfield, 20, 1, :market_specific_data_identified, "BM 62: Market Specific Data Identified" )
  FixedPositionSubfield.new.set_subfield( F62_string_id2subfield, 21, 2, :duration, "BM 62: Duration" )
  FixedPositionSubfield.new.set_subfield( F62_string_id2subfield, 23, 1, :prestigious_property_indicator, "BM 62: Prestigious Property Indicator" )
  FixedPositionSubfield.new.set_subfield( F62_string_id2subfield, 24, 2, :card_level_results, "BM 62: Card Level Results" )

  ##############################################################################
  F62_Codec = Codec.new
  F62_Codec.encoder = lambda{ |params_hashtable, message|
#puts "params_hashtable = " + params_hashtable.map{|k,v| "#{k}='#{v}'"}.join(' & ')
      serialize_fixed_subfields(   62, F62_string_id2subfield, params_hashtable, message )
  }
  F62_Codec.decoder = lambda {  |raw, message|
      deserialize_fixed_subfields( 62, F62_string_id2subfield, raw, message )
  }
    
    
    


end # Module