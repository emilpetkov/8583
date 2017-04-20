module ISO8583
  PAYNETICS_SUBFIELD_LENGTH_PREFIX = 3.freeze
  PAYNETICS_SUBFIELD_NUMBER_LENGTH = 2.freeze
  # Listed here are only the subfield definitions that are used
  PAYNETICS_SUBFIELD_DEFINITIONS = {
    cvv2: { name: 'CVV2', number: '30', codec: EBCDIC_Codec},
    electronic_commerce_indicator: { name: 'Indicator for electronic commerce', number: '40', codec: EBCDIC_Codec },
    xid: { name: 'XID', number: '61', codec: Binary_Codec },
    cardholder_authentication_value: { name: 'Cardholder Authentication Value', number: '62', codec: Binary_Codec }
  }
end
