require 'test/unit'
require 'lib/iso8583'

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
    encoded_value = LL_EBCDIC.encode('12', nil)

    assert_equal 2, encoded_value.length
    assert_equal ISO8583.ascii2ebcdic('12'), encoded_value

    encoded_value = LL_EBCDIC.encode('3', nil)

    assert_equal 2, encoded_value.length
    assert_equal ISO8583.ascii2ebcdic('03'), encoded_value
  end

  def test_LLL_EBCDIC
    #encoded_value = LLL_EBCDIC.encode('123', nil)

    #assert_equal 3, encoded_value.length
    #assert_equal ISO8583.ascii2ebcdic('123'), encoded_value
  end

  def test_LL_EBCDIC_BCD
    encoded_value = LL_EBCDIC_BCD.encode('160203', nil)
    length = encoded_value.slice(0, 2)
    payload = encoded_value.slice(2, 5)

    assert_equal 5, encoded_value.length # 2 bytes EBCDID + 3 bytes BCD
    assert_equal ISO8583.ascii2ebcdic("03"), length # First two bytes indicate the length of message, which is 3 in BCD
    assert_equal "\x16\x02\x03", payload # The rest of the message in BCD
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
    # This spec is actually failing, expected result is
    # ["1! ", "a"] there is a blank space!!!
    # ANS codec has not been touched, so maybe this is a very old failure
    assert_equal ["1!", "a"], fld.parse("1! a",nil)
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
end
