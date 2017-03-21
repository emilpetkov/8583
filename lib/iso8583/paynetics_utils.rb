module ISO8583
  # Listed here are only the subfield definitions that are used
  PAYNETICS_SUBFIELD_DEFINITIONS = {
    'CVV2' => { number: '30', codec: EBCDIC_Codec},
    'Indicator for electronic commerce' => { number: '40', codec: EBCDIC_Codec },
    'XID' => { number: '61', codec: '' },
    'Cardholder Authentication Value' => { number: '62', codec: '' }
  }
end
