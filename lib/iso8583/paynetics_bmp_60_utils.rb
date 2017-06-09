module ISO8583
  PAYNETICS_SUBFIELD_LENGTH_PREFIX = 3.freeze
  PAYNETICS_SUBFIELD_NUMBER_LENGTH = 2.freeze
  # Listed here are only the subfield definitions that are used
  PAYNETICS_SUBFIELD_DEFINITIONS = {
    cvv2: { name: 'CVV2', number: '30', codec: EBCDIC_Codec},
    electronic_commerce_indicator: { name: 'Indicator for electronic commerce', number: '40', codec: EBCDIC_Codec },
    xid: { name: 'XID', number: '61', codec: No_change_codec },
    cavv: { name: 'Cardholder Authentication Value', number: '62', codec: No_change_codec },
    recurring_payment_indicator: { name: 'Indicator for recurring', number: '41', codec: EBCDIC_Codec },
    ucaf: { name: 'Universal Cardholder Authentication Field', number: '63', codec: EBCDIC_Codec },
    payment_facilitator_id: { name: 'Payment Facilitator ID', number: '81', codec: Packed_Number },
    independent_sales_organization: { name: 'Independent Sales Organization', number: '82', codec: Packed_Number },
    sub_merchant_id: { name: 'Sub Merchant ID', number: '83', codec: EBCDIC_Codec },
    zip_code: { name: 'Zip Code', number: '84', codec: EBCDIC_Codec }
  }
end
