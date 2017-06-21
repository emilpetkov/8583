module ISO8583
  PAYNETICS_SUBFIELD_LENGTH_PREFIX = 3.freeze
  PAYNETICS_SUBFIELD_NUMBER_LENGTH = 2.freeze
  # Listed here are only the subfield definitions that are used
  PAYNETICS_SUBFIELD_DEFINITIONS = {
    cvv2:                          { name: 'CVV2', number: '30', codec: EBCDIC_Codec},
    avs_request:                   { name: 'Address Verification Data Request', number: '31', codec: EBCDIC_Codec},
    avs_response:                  { name: 'Address Verification Data Response', number: '32', codec: EBCDIC_Codec},
    electronic_commerce_indicator: { name: 'Indicator for electronic commerce', number: '40', codec: EBCDIC_Codec },
    xid:                           { name: 'XID', number: '61', codec: No_change_codec },
    cavv:                          { name: 'Cardholder Authentication Value', number: '62', codec: No_change_codec },
    recurring_payment_indicator:   { name: 'Indicator for recurring', number: '41', codec: EBCDIC_Codec },
    ucaf:                          { name: 'Universal Cardholder Authentication Field', number: '63', codec: EBCDIC_Codec },
    payment_facilitator_id:        { name: 'Payment Facilitator ID', number: '81', codec: EBCDIC_Codec },
    iso_id:                        { name: 'Independent Sales Organization', number: '82', codec: EBCDIC_Codec },
    sub_merchant_id:               { name: 'Sub Merchant ID', number: '83', codec: EBCDIC_Codec },
    sub_merchant_address:          { name: 'Sub Merchant Address', number: '84', codec: EBCDIC_Codec }
  }
end
