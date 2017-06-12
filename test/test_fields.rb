require 'test/unit'
require_relative '../lib/iso8583'
require 'byebug'
include ISO8583

class FieldTest < Test::Unit::TestCase
  def test_LLL
    value, rest = LLL.parse "123456", nil
    assert_equal 123, value
    assert_equal "456", rest

    assert_raise(ISO8583ParseException) {
      LLL.parse "12", nil
    }

    enc = LLL.encode 123, nil
    assert_equal "\x31\x32\x33", enc

    enc = LLL.encode "123", nil
    assert_equal "\x31\x32\x33", enc

    enc = LLL.encode 12, nil
    assert_equal "\x30\x31\x32", enc

    #enc = LLL.encode "012"
    #assert_equal "\x30\x31\x32", enc


    assert_raise(ISO8583Exception) {
      LLL.encode 1234, nil
    }

    assert_raise(ISO8583Exception) {
      LLL.encode "1234", nil
    }
  end

  def test_LL_EBCDIC
    # The length is always 2 bytes, value is right justified, zeros are added if necessary
    encoded_value = LL_EBCDIC.encode('12', nil)

    assert_equal 2, encoded_value.length
    assert_equal ISO8583.ascii2ebcdic('12'), encoded_value

    encoded_value = LL_EBCDIC.encode('3', nil)

    assert_equal 2, encoded_value.length
    assert_equal ISO8583.ascii2ebcdic('03'), encoded_value

    value, rest = LL_EBCDIC.parse("\xf2\xf3\xf4", nil)

    assert_equal 23, value
    assert_equal "\xf4", rest
  end

  def test_LLL_EBCDIC
    # The length is always 3 bytes, value is right justified, zeros are added if necessary
    encoded_value = LLL_EBCDIC.encode('9', nil)

    assert_equal 3, encoded_value.length
    assert_equal ISO8583.ascii2ebcdic('009'), encoded_value

    encoded_value = LLL_EBCDIC.encode('13', nil)

    assert_equal 3, encoded_value.length
    assert_equal ISO8583.ascii2ebcdic('013'), encoded_value

    value, rest = LLL_EBCDIC.parse("\xf2\xf3\xf4\xf5", nil)

    assert_equal 234, value
    assert_equal "\xf5", rest
  end

  def test_LL_EBCDIC_BCD
    codec = LL_EBCDIC_BCD
    codec.max = 11
    encoded_value = codec.encode('160203', nil)
    length = encoded_value.slice(0, 2)
    payload = encoded_value.slice(2, 5)

    assert_equal 5, encoded_value.length # 2 bytes EBCDID + 3 bytes BCD
    assert_equal ISO8583.ascii2ebcdic("03"), length # First two bytes indicate the length of message, which is 3 in BCD
    assert_equal "\x16\x02\x03", payload # The rest of the message in BCD


    # Actual Maestro card
    encoded_value = LL_EBCDIC_BCD.encode('5450880240000000017', nil)
    length = encoded_value.slice(0, 2)
    payload = encoded_value.slice(2, encoded_value.length)

    assert_equal 12, encoded_value.length # 2 bytes EBCDIC + payload
    assert_equal "TP\x88\x02@\x00\x00\x00\x01\x7F".force_encoding('ASCII-8BIT'), payload

    # Actual VISA card
    encoded_value = LL_EBCDIC_BCD.encode('4018490000000013', nil)
    length = encoded_value.slice(0, 2)
    payload = encoded_value.slice(2, encoded_value.length)

    assert_equal 10, encoded_value.length # 2 bytes EBCDIC + payload
    assert_equal "@\x18I\x00\x00\x00\x00\x13".force_encoding('ASCII-8BIT'), payload

    value, rest = LL_EBCDIC_BCD.parse("\xf0\xf3\x16\x02\x03\x04", nil)
    assert_equal 160203, value
    assert_equal "\x04", rest

    value, rest = LL_EBCDIC_BCD.parse("\xf0\xf8@\x18I\x00\x00\x00\x00\x13", nil)
    assert_equal 4018490000000013, value

    value, rest = LL_EBCDIC_BCD.parse("\xf1\xf0TP\x88\x02@\x00\x00\x00\x01\x7F", nil)
    assert_equal 5450880240000000017, value
  end

  def test_LLL_EBCDIC_BCD
    encoded_value = LLL_EBCDIC_BCD.encode('160203', nil)
    length = encoded_value.slice(0, 3)
    payload = encoded_value.slice(3, 6)

    assert_equal 6, encoded_value.length # 3 bytes EBCDID + 3 bytes BCD
    assert_equal ISO8583.ascii2ebcdic("003"), length # First two bytes indicate the length of message, which is 3 in BCD
    assert_equal "\x16\x02\x03", payload # The rest of the message in BCD

    value, rest = LLL_EBCDIC_BCD.parse("\xf0\xf0\xf3\x16\x02\x03\x04", nil)
    assert_equal 160203, value
    assert_equal "\x04", rest
  end

  def test_LLL_EBCDIC_ANS
    encoded_value = LLL_EBCDIC_ANS.encode('80', nil)
    length = encoded_value.slice(0, 3)
    payload = encoded_value.slice(3, 5)

    assert_equal ISO8583.ascii2ebcdic('80'), payload
    assert_equal ISO8583.ascii2ebcdic('002'), length

    value, rest = LLL_EBCDIC_ANS.parse("\xf0\xf0\xf2\xf8\xf0\xf5", nil)
    assert_equal '80', value
    assert_equal "\xf5", rest
  end

  def test_LL_EBCDIC_ANS
    encoded_value = LL_EBCDIC_ANS.encode('Descriptor               Sofia        AF', nil)
    length = encoded_value.slice(0, 2)
    payload = encoded_value.slice(2, encoded_value.length)

    assert_equal "\xF4\xF0\xC4\x85\xA2\x83\x99\x89\x97\xA3\x96\x99@@@@@@@@@@@@@@@\xE2\x96\x86\x89\x81@@@@@@@@\xC1\xC6".force_encoding('ASCII-8BIT'), encoded_value
    assert_equal ISO8583.ascii2ebcdic('Descriptor               Sofia        AF'), payload
    assert_equal ISO8583.ascii2ebcdic('40'), length

    value, rest = LL_EBCDIC_ANS.parse("\xf0\xf6\xf0\xf0\xf2\xf8\xf0\xf5\xf7\xf3", nil)
    assert_equal '002805', value
    assert_equal "\xf7\xf3", rest
  end

  def test_EBCDIC_AN
    codec = EBCDIC_AN
    codec.length = 8
    encoded_value = codec.encode('99F30003', nil)
    assert_equal "\xF9\xF9\xC6\xF3\xF0\xF0\xF0\xF3".force_encoding("ASCII-8BIT"), encoded_value

    value, rest = codec.parse("\xF9\xF9\xC6\xF3\xF0\xF0\xF0\xF3", nil)
    assert_equal '99F30003', value
    assert_equal '', rest

    # Note the blanks after the encoded value
    padding_codec = EBCDIC_AN
    padding_codec.length = 10
    encoded_value = padding_codec.encode('99F30003', nil)
    assert_equal "\xF9\xF9\xC6\xF3\xF0\xF0\xF0\xF3  ".force_encoding("ASCII-8BIT"), encoded_value

    value, rest = padding_codec.parse("\xF9\xF9\xC6\xF3\xF0\xF0\xF0\xF3  ", nil)
    # What the hell is EBCDIC for empty ??
    #assert_equal "99F30003  ", value
    assert_equal '', rest
  end

  def test_LL_BCD
    value, rest = LL_BCD.parse "\x123456", nil
    assert_equal 12, value
    assert_equal "3456", rest
  end

  def test_LLVAR_AN
    value, rest = LLVAR_AN.parse "03123ABC", nil
    assert_equal "123", value
    assert_equal "ABC", rest

    value, rest = LLLVAR_AN.parse "006123ABC", nil
    assert_equal "123ABC", value
    assert_equal "", rest
    assert_raise(ISO8583ParseException) {
      LLLVAR_AN.parse "12", nil
    }
    assert_raise(ISO8583ParseException) {
      LLVAR_AN.parse "12123", nil
    }

    enc = LLVAR_AN.encode "123A", nil
    assert_equal "04123A", enc

    enc = LLVAR_AN.encode "123ABC123ABC", nil
    assert_equal "12123ABC123ABC", enc

    assert_raise(ISO8583Exception) {
      LLVAR_AN.encode "1234 ABCD", nil
    }

    enc = LLLVAR_AN.encode "123ABC123ABC", nil
    assert_equal "012123ABC123ABC", enc

    assert_raise(ISO8583Exception) {
      LLLVAR_AN.encode "1234 ABCD", nil
    }
  end

  def test_LLVAR_N
    value, rest = LLVAR_N.parse "021234", nil
    assert_equal 12, value
    assert_equal "34", rest

    value, rest = LLLVAR_N.parse "0041234", nil
    assert_equal 1234, value
    assert_equal "", rest
    assert_raise(ISO8583ParseException) {
      LLLVAR_N.parse "12", nil
    }
    assert_raise(ISO8583ParseException) {
      LLVAR_N.parse "12123", nil
    }

    enc = LLVAR_N.encode 1234, nil
    assert_equal "041234", enc

    enc = LLVAR_N.encode 123412341234, nil
    assert_equal "12123412341234", enc

    assert_raise(ISO8583Exception) {
      enc = LLVAR_N.encode "1234ABCD", nil
    }

    enc = LLLVAR_N.encode "123412341234", nil
    assert_equal "012123412341234", enc

    assert_raise(ISO8583Exception) {
      enc = LLLVAR_N.encode "1234ABCD", nil
    }
  end

  def test_LLVAR_Z
    value, rest = LLVAR_Z.parse "16;123123123=123?5"+"021234", nil
    assert_equal ";123123123=123?5", value
    assert_equal "021234", rest

    value, rest = LLVAR_Z.parse "16;123123123=123?5", nil
    assert_equal ";123123123=123?5", value
    assert_equal "", rest
    assert_raise(ISO8583ParseException) {
      LLVAR_Z.parse "12", nil
    }
    assert_raise(ISO8583ParseException) {
      LLVAR_Z.parse "17;123123123=123?5", nil
    }

    enc = LLVAR_Z.encode ";123123123=123?5", nil
    assert_equal "16;123123123=123?5", enc

    assert_raise(ISO8583Exception) {
      enc = LLVAR_Z.encode "1234ABCD", nil
    }
  end

  def test_A
    fld = A.dup
    fld.length = 3
    value, rest = fld.parse "abcd", nil
    assert_equal "abc", value
    assert_equal "d", rest

    assert_raise(ISO8583ParseException) {
      fld.parse "ab", nil
    }

    assert_raise(ISO8583Exception) {
      fld.encode "abcdef", nil
    }
  end

  def test_AN
    fld = AN.dup
    fld.length = 3
    value, rest = fld.parse "1234", nil
    assert_equal "123", value
    assert_equal "4", rest

    assert_raise(ISO8583ParseException) {
      fld.parse "12", nil
    }

    assert_raise(ISO8583Exception) {
      fld.encode "888810", nil
    }
  end

  def test_ANP
    fld = ANP.dup
    fld.length = 3
    value, rest = fld.parse "1234", nil
    assert_equal "123", value
    assert_equal "4", rest

    assert_raise(ISO8583ParseException) {
      fld.parse "12", nil
    }

    assert_equal "10 ", fld.encode("10", nil)
  end

  def test_ANS
    fld = ANS.dup
    fld.length = 3
    value, rest = fld.parse "1234", nil
    assert_equal "123", value
    assert_equal "4", rest

    assert_raise(ISO8583ParseException) {
      fld.parse "12", nil
    }

    assert_equal "10 ", fld.encode("10", nil)
    # IMPORTANT!!!
    # This spec was originally failing.
    # The length of the field is set to 3, so this means that
    # "1! a" should be parsed as "1! " and "a" is the rest
    assert_equal ["1! ", "a"], fld.parse("1! a",nil)
  end

  def test_B
    fld = B.dup
    fld.length = 3
    value, rest = fld.parse "\000234", nil
    assert_equal "\00023", value
    assert_equal "4", rest

    assert_raise(ISO8583ParseException) {
      fld.parse "12", nil
    }

    assert_equal "10\000", fld.encode("10", nil)
    assert_equal ["1! ", "a"], fld.parse("1! a", nil)
    assert_equal ["1!", ""], fld.parse("1!\000", nil)
  end

  def test_N_BCD
    fld = N_BCD.dup
    fld.length=3
    value, _rest = fld.parse "\x01\x23\x45", nil
    assert_equal 123, value

    assert_equal "\x01\x23", fld.encode(123, nil)
    assert_equal "\x01\x23", fld.encode("123", nil)
    assert_equal "\x01\x23", fld.encode("0123", nil)

    assert_raise(ISO8583Exception) {
      fld.encode 12345, nil
    }

    # There's a bug here. A 4 digit value encodes to 2 digits encoded, 
    # which passes the test for length ... This test doesn't pass:

    #asssert_raise (ISO8583Exception) {
    #  fld.encode 1234
    #}
  end

  def test_YYMMDDhhmmss
    fld = YYMMDDhhmmss
    assert_equal "740808120000", fld.encode("740808120000", nil)
  end

  def test_LLL_SUBFIELD_BMP_60
    encoded_value = LLL_SUBFIELD_BMP_60.encode({ electronic_commerce_indicator: '07' }, nil)
    assert_equal encoded_value, "\xF0\xF0\xF7\xF0\xF0\xF4\xF4\xF0\xF0\xF7".force_encoding('ASCII-8BIT')

    encoded_value = LLL_SUBFIELD_BMP_60.encode({ electronic_commerce_indicator: '07',
                                                 cvv2: '0299' }, nil)
    assert_equal encoded_value, "\xF0\xF1\xF6\xF0\xF0\xF4\xF4\xF0\xF0\xF7\xF0\xF0\xF6\xF3\xF0\xF0\xF2\xF9\xF9".force_encoding('ASCII-8BIT')

    encoded_value = LLL_SUBFIELD_BMP_60.encode({ recurring_payment_indicator: '02' }, nil)
    assert_equal encoded_value, "\xF0\xF0\xF7\xF0\xF0\xF4\xF4\xF1\xF0\xF2".force_encoding('ASCII-8BIT')

    encoded_value = LLL_SUBFIELD_BMP_60.encode({ ucaf: 'jNLN3CUNxntECBNul08SCHQAAAA=' }, nil)
    assert_equal encoded_value, "\xF0\xF3\xF3\xF0\xF3\xF0\xF6\xF3\x91\xD5\xD3\xD5\xF3\xC3\xE4\xD5\xA7\x95\xA3\xC5\xC3\xC2\xD5\xA4\x93\xF0\xF8\xE2\xC3\xC8\xD8\xC1\xC1\xC1\xC1~".force_encoding('ASCII-8BIT')

    encoded_value = LLL_SUBFIELD_BMP_60.encode({ xid: 'MDAwMDAwMDAwMDAxNTQzODgyNFg=', cavv: 'jNLN3CUNxntECBNul08SCHQAAAA=' }, nil)
    assert_equal encoded_value, "\xF0\xF6\xF6\xF0\xF3\xF0\xF6\xF1MDAwMDAwMDAwMDAxNTQzODgyNFg=\xF0\xF3\xF0\xF6\xF2jNLN3CUNxntECBNul08SCHQAAAA=".force_encoding('ASCII-8BIT')

    encoded_value = LLL_SUBFIELD_BMP_60.encode({ payment_facilitator_id: '00001111222',
                                                 independent_sales_organization: '00003456789' }, nil)
    assert_equal encoded_value, "\xF0\xF2\xF2\xF0\xF1\xF3\xF8\xF1\x00\x00\x01\x11\x12\"\xF0\xF1\xF3\xF8\xF2\x00\x00\x03Eg\x89".force_encoding('ASCII-8BIT')

    encoded_value = LLL_SUBFIELD_BMP_60.encode({ independent_sales_organization: '00003456789' }, nil)
    assert_equal encoded_value, "\xF0\xF1\xF1\xF0\xF1\xF3\xF8\xF2\x00\x00\x03Eg\x89".force_encoding('ASCII-8BIT')

    value, _rest = LLL_SUBFIELD_BMP_60.parse("\xF0\xF1\xF6\xF0\xF0\xF4\xF4\xF0\xF0\xF7\xF0\xF0\xF6\xF3\xF0\xF0\xF2\xF9\xF9", nil)
    assert_equal value, {'Indicator for electronic commerce' => '07', 'CVV2' => '0299'}

    value, _rest = LLL_SUBFIELD_BMP_60.parse("\xF0\xF6\xF6\xF0\xF3\xF0\xF6\xF1MDAwMDAwMDAwMDAxNTQzODgyNFg=\xF0\xF3\xF0\xF6\xF2jNLN3CUNxntECBNul08SCHQAAAA=", nil)
    assert_equal value, { 'Cardholder Authentication Value' => "jNLN3CUNxntECBNul08SCHQAAAA=",
                          'XID' => "MDAwMDAwMDAwMDAxNTQzODgyNFg=" }

    value, _rest = LLL_SUBFIELD_BMP_60.parse("\xF0\xF1\xF1\xF0\xF1\xF3\xF8\xF2\x00\x00\x03Eg\x89".force_encoding('ASCII-8BIT'), nil)
    assert_equal value, { 'Independent Sales Organization' => 3456789 }
  end

  def test_LLL_EBCDIC_BMP_57
    field = LLL_EBCDIC_BMP_57
    field.suffix_value = 0
    encoded_value = field.encode('1', nil)
    # length in EBCDIC, actual data is always 8 bytes, suffix is 2 BCDs
    assert_equal encoded_value, "\xF0\xF0\xF9\xF0\xF0\xF0\xF0\xF0\xF0\xF0\xF1\x00".force_encoding('ASCII-8BIT')

    field = LLL_EBCDIC_BMP_57
    field.suffix_value = 0
    value, _rest = field.parse("\xF0\xF0\xF9\xF0\xF0\xF0\xF0\xF0\xF0\xF0\xF1\x00", nil)

    assert_equal value, "00000001\x00"
  end
end
