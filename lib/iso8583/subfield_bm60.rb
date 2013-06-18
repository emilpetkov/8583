# Copyright 2013 by eMerchantPay. Author: Georgi Mitev (g.mitev@emerchantpay.com)

module ISO8583
  


  F60_string_id2subfield = Hash.new
  F60_numeric_id2subfield = Hash.new
  
  LLLXXFixedSizeSubfield.new.set_subfield( F60_numeric_id2subfield, F60_string_id2subfield,  1, 30, :cvv2_presence_indicator, "BM60: CVV2 Presence Indicator (Visa CNP Only)", false )
  LLLXXFixedSizeSubfield.new.set_subfield( F60_numeric_id2subfield, F60_string_id2subfield, 49, 31, :address_verification_data_request, "BM60: Address Verification Data, Request", false )
  LLLXXFixedSizeSubfield.new.set_subfield( F60_numeric_id2subfield, F60_string_id2subfield,  2, 32, :address_verification_data_response, "BM60: Address Verification Data, Response", false, BM60::ADDRESS_VERIFICATION_DATA_RESPONSE_TRANSLATION )
  LLLXXSubfield.new.set_subfield(          F60_numeric_id2subfield, F60_string_id2subfield,     35, :merchant_post_code, "BM60: Merchant Post Code", false )
  LLLXXFixedSizeSubfield.new.set_subfield( F60_numeric_id2subfield, F60_string_id2subfield, 29, 37, :dynamic_currency_conversion_data, "BM60: Dynamic Currency Conversion (DCC) Data", false )
  LLLXXFixedSizeSubfield.new.set_subfield( F60_numeric_id2subfield, F60_string_id2subfield,  2, 40, :electronic_commerce_indicator, "BM60: Electronic Commerce Indicator (ECI)", false )
  LLLXXFixedSizeSubfield.new.set_subfield( F60_numeric_id2subfield, F60_string_id2subfield,  1, 51, :recurring_payment_indicator, "BM60: Recurring Payment Indicator", false )
  LLLXXFixedSizeSubfield.new.set_subfield( F60_numeric_id2subfield, F60_string_id2subfield,  2, 52, :recurring_payment_response, "BM60: Recurring Payment Response", false )
  LLLXXFixedSizeSubfield.new.set_subfield( F60_numeric_id2subfield, F60_string_id2subfield,  3, 53, :terminal_capabilities, "BM60: Terminal Capabilities", false )
  LLLXXFixedSizeSubfield.new.set_subfield( F60_numeric_id2subfield, F60_string_id2subfield, 99, 54, :batch_information, "BM60: Batch Information", false ) # TODO, when available more info
  LLLXXFixedSizeSubfield.new.set_subfield( F60_numeric_id2subfield, F60_string_id2subfield, 30, 55, :additional_authorisation_data, "BM60: Additional Authorisation Data", false )
  LLLXXFixedSizeSubfield.new.set_subfield( F60_numeric_id2subfield, F60_string_id2subfield, 40, 61, :xid, "BM60: XID", false )
  LLLXXFixedSizeSubfield.new.set_subfield( F60_numeric_id2subfield, F60_string_id2subfield, 40, 62, :cavv, "BM60: CAVV (VISA Cardholder Authentication Verification Value  - CAVV – 3D Secure", false )
  LLLXXSubfield.new.set_subfield(          F60_numeric_id2subfield, F60_string_id2subfield,     63, :ucaf, "BM60: UCAF Data", false )
  LLLXXFixedSizeSubfield.new.set_subfield( F60_numeric_id2subfield, F60_string_id2subfield,  6, 64, :mastercard_assigned_id, "BM60: MasterCard Assigned ID", false )

  ##############################################################################
  F60_Codec = Codec.new
  F60_Codec.encoder = lambda{ |params_hashtable, message|
#puts "params_hashtable = " + params_hashtable.map{|k,v| "#{k}='#{v}'"}.join(' & ')
      serialize_lllxx_subfields(   60, F60_string_id2subfield, params_hashtable, message )
  }

  F60_Codec.decoder = lambda {  |raw, message|
      deserialize_lllxx_subfields( 60, F60_numeric_id2subfield, raw, message )
  }
    
    
    


end # Module