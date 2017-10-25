module ISO8583
  module BM60
    
    NO_INFO = nil
    
    ADDRESS_VERIFICATION_DATA_RESPONSE_TRANSLATION1 = {
      "2" => "Response provided by Intermediate processor",
      "5" => "Response provided by issuer processor"
    }

    ADDRESS_VERIFICATION_DATA_RESPONSE_TRANSLATION2 = {
			"A" => "Street address matches, but 5-digit and 9-digit postal code do not match.",
      "B" => "Street address matches, but postal code not verified due to incompatible formats.",
      "C" => "Street address and postal code not verified due to incompatible formats.",
      "D" => "Street address and postal code match.",
      "E" => "AVS data is invalid or AVS is not allowed for this card type.",
      "F" => "1. For AMERICAN_EXPRESS only:'Card member's name does not match, but billing postal code matches.' 2. For VISA only: 'Street address and postal code match. Applies to U.K. only.'",
      "G" => "Address not verified for international transaction. Issuer is not an Address Verification Service (AVS) participant, or AVS data was present in the request but issuer did not return an AVS result, or V.I.P. performed address verification on behalf of the issuer and there was no address record on file for this account",
      "I" => "Address information not verified.",
      "H" => "American Express: Card member's name does not match. Street address and postal code match.",
      "J" => "American Express: Card member's name, billing address, and postal code match.",
      "K" => "American Express: Card member's name matches but billing address and billing postal code do not match.",
      "L" => "American Express: Card member's name and billing postal code match, but billing address does not match.",
      "M" => "Street addresses and postal/ZIP codes match.",
      "N" => "No match. Acquirer sent postal/ZIP code only, or street address only, or both postal/ZIP and street address.",
      "O" => "American Express: Card member's name and billing address match, but billing postal code does not match.",
      "P" => "Postal/ZIP codes match. Acquirer sent both postal/ZIP code and street address, but street address not verified due to incompatible formats.",
      "R" => "Retry: System unavailable or timed out. Issuer ordinarily performs address verification but was unavailable.",
      "S" => "Not applicable. If present, V.I.P. replaces it with U or with G.",
      "T" => "American Express: Card member's name does not match, but street address matches.",
      "U" => "MasterCard: 'No data from issuer/Authorization system'. Visa: Address not verified for domestic transaction. Address not verified for international transaction. Issuer is not an AVS participant, or AVS data was present in the request but issuer did not return an AVS result, or V.I.P. performed address verification on behalf of the issuer and there was no address record on file for this account.",
      "V" => "American Express: Card member's name, billing address, and billing postal code match.",
      "W" => "1. Standard domestic: 'Street address does not match, but 9-digit postal code matches.' 2. VISA: 'Not applicable. If present, Visa V.I.P. replaces it with Z. Available for U.S. issuers only.'",
      "X" => "1. Standard domestic: 'Street address and 9-digit postal code match.' 2. VISA: 'Not applicable. If present, V.I.P. replaces it with Y. Available for U.S. issuers only.'",
      "Y" => "Street address and postal/ZIP match.",
      "Z" => "Postal/ZIP match, street addresses do not match or street address not inclued in request."
    }
    
    ADDRESS_VERIFICATION_DATA_RESPONSE_TRANSLATION = Hash.new

    ADDRESS_VERIFICATION_DATA_RESPONSE_TRANSLATION1.each_pair do |byte1,translation1|
      ADDRESS_VERIFICATION_DATA_RESPONSE_TRANSLATION2.each_pair do |byte2,translation2|
        ADDRESS_VERIFICATION_DATA_RESPONSE_TRANSLATION[ (byte1 + byte2) ] = (translation1+"; "+translation2)
      end
    end
    
    RECURRING_PAYMENT_RESPONSE_TRANSLATION = {
			'01' => 'New Account Information available',
			'02' => 'Try again later',
			'03' => 'Do not try again',
			'21' => 'Recurring Payment Cancellation Service'
    }
  end
end