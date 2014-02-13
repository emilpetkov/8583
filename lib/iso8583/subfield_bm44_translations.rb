module ISO8583
  module BM44 
    
    NO_INFO = nil
    
    MASTERCARD_RESULT_CODE_TRANSLATION = {
      " " => NO_INFO,
			"M" => "CVC2 match",
			"N" => "CVC2 no match",
			"P" => "Not Processed",
			"U" => "Issuer is not certified",
			"Y" => "CVC1 Incorrect"
    }
    VISA_REASON_CODE_TRANSLATION = {
      "0" => "Advice of Exception File change",
      "1" => "Response provided by STIP because the request was timed out by Switch",
      "2" => "Response provided by STIP because the transaction amount was below issuer limit",
      "3" => "Response provided by STIP because the issuer is in Suppress Inquiries mode",
      "4" => "Response provided by STIP because issuer not available",
      "5" => "Response provided by issuer",
      "6" => "Enhanced STIP reason code provided on behalf of third-party processor",
      "7" => "Reversal advice provided by VISA to identify a potential duplicate transaction",
      "8" => "Reversal advice provided by VISA to identify a probable duplicate authorization",
      "9" => "Enhanced STIP reason code provided by the VISA International Automated Referral Service",
      "A" => "Response provided by a third-party authorizing agent (POS Check)",
      " " => NO_INFO
    }
    
    VISA_AVR_CODE_TRANSLATION = {
      "A" => "Address matches, ZIP does not",
      "B" => "Address matches, ZIP not verified due to incompatible format",
      "C" => "Address and ZIP not verified due to incompatible formats",
      "D" => "Street and postal codes match (international)",
      "F" => "Street and postal codes match (U. K. only)",
      "G" => "Address information not verified for international transaction",
      "I" => "Address information not verified for international transaction",
      "M" => "Street and postal codes match (international)",
      "N" => "No: Neither address or ZIP matches",
      "P" => "Postal code match. Street address not verified due to incompatible format",
      "R" => "Retry: System unavailable or timed out",
      "U" => "Address information unavailable",
      "Y" => "Exact: Address and ZIP match",
      "Z" => "ZIP matches, address does not",
      " " => NO_INFO
    }
    
    VISA_RESERVED3_TRANSLATION = {
      " " => NO_INFO
    }
    
    VISA_CARD_PRODUCT_TYPE_TRANSLATION = {
      " " => NO_INFO
    }
    
    VISA_CVV_RESULT_CODE_TRANSLATION = {
      "1" => "CVV/dCVV failed verification", 
      "2" => "CVV/dCVV passed verification",
      " " => "CVV/dCVV not verified or fill for subsequent positions that are present"
    }
    
    VISA_PACM_DIVERSION_LEVEL_TRANSLATION = {
      " " => NO_INFO
    }
    
    VISA_PACM_REASON_CODE_TRANSLATION = {
      " " => NO_INFO
    }
    
    VISA_RESERVED8_TRANSLATION = {
      
    }
    
    VISA_CARD_AUTHENTICATION_RESULT_CODE_TRANSLATION = {
      " " => NO_INFO
    }
    
    VISA_CVV2_RESULT_CODE_TRANSLATION = {
      " " => NO_INFO,
			"M" => "CVC2 match",
			"N" => "CVC2 no match",
			"P" => "Not Processed",
      "S" => "The CVV2 should be on the card, but the merchant indicates it is not"
    }
    
    VISA_ORIGINAL_RESPONSE_CODE_TRANSLATION = {
      " " => NO_INFO
    }
    
    VISA_CHECK_SETTLMENT_CODE_TRANSLATION = {
			"1" => "VISA settlement code",
      "2" => "ACH settlement code"
    }
    
    VISA_CAVV_RESULT_CODE_TRANSLATION = {
      " " => "CAVV not present",
      "0" => "CAVV not validated due to erroneous data submitted",
      "1" => "CAVV failed validation – authentication",
      "2" => "CAVV passed validation – authentication",
      "3" => "CAVV passed validation – attempt. A 3-D Secure authentication value of 7 from the issuer’s ACS indicates that authentication was attempted. (Determined that the issuer’s ACS generated this value from the use of the Issuer’s CAVV key[s])",
      "4" => "CAVV failed validation – attempt. A 3-D Secure authentication value of 7 from the issuer’s ACS indicates that authentication was attempted. (Determined that the issuer’s ACS generated this value from the use of the Issuer’s CAVV key[s])",
      "5" => "Not used (reserved for future use)",
      "6" => "CAVV not validated, issuer not participating in CAVV validation",
      "7" => "CAVV failed validation – attempt. A 3-D Secure authentication value of 7 from VISA’s ACS indicates that an authentication attempt was performed. (Determined that the VISA generated this value from the use of VISA’s CAVV key[s])",
      "8" => "CAVV passed validation – attempt. A 3-D Secure authentication value of 7 from VISA’s ACS indicates that an authentication attempt was performed. (Determined that the VISA generated this value from the use of VISA’s CAVV key[s])",
      "9" => "CAVV failed validation – attempt. A 3-D Secure authentication value of 8 from VISA’s ACS indicates that authentication attempt was performed when the issuer’s ACS was not available. (Determined that VISA generated this value from the use of the VISA CAVV key[s])",
      "A" => "CAVV passed validation – attempt. A 3-D Secure authentication value of 8 from VISA’s ACS indicates that authentication attempt was performed when the issuer’s ACS was not available. (Determined that VISA generated this value from the use of the VISA CAVV key[s])",
      "B" => "CAVV passed validation – information only, no liability shift. When the ECI equals 7 and CAVV is present, the CAVV will be validated but no liability shift will occur. VISA will generate this value for card or transaction types that are not eligible for the 3-D Secure service",
      "C" => "CAVV was not validated – attempt. The issuer did not return a CAVV results code in the authorization response",
      "D" => "CAVV was not validated – authentication. The issuer did not return a CAVV results code in the authorization response"
    }
    
    VISA_RESPONSE_REASON_CODE_TRANSLATION = {
      
    }
  end
end