require 'test/unit'
require_relative '../lib/iso8583'

include ISO8583

class FieldTest < Test::Unit::TestCase
  def test_MMDDhhmmssCodec
    dt = MMDDhhmmssCodec.decode "1212121212"
    assert_equal DateTime, dt.class
    assert_equal 12, dt.month
    assert_equal 12, dt.day
    assert_equal 12, dt.hour
    assert_equal 12, dt.min
    assert_equal 12, dt.sec

    assert_raise(ISO8583Exception) {
      dt = MMDDhhmmssCodec.decode "1312121212"
    }

    assert_raise(ISO8583Exception) {
      dt = MMDDhhmmssCodec.encode "1312121212"
    }

    assert_equal "1212121212", MMDDhhmmssCodec.encode("1212121212")
  end

  def test_YYMMDDhhmmssCodec
    dt = YYMMDDhhmmssCodec.decode "081212121212"
    assert_equal DateTime, dt.class
    assert_equal 2008, dt.year
    assert_equal 12, dt.month
    assert_equal 12, dt.day
    assert_equal 12, dt.hour
    assert_equal 12, dt.min
    assert_equal 12, dt.sec

    assert_raise(ISO8583Exception) {
      dt = YYMMDDhhmmssCodec.decode "091312121212"
    }

    assert_raise(ISO8583Exception) {
      dt = YYMMDDhhmmssCodec.encode "091312121212"
    }

    assert_equal "091212121212", YYMMDDhhmmssCodec.encode("091212121212")
  end

  def test_YYMMCodec
    dt = YYMMCodec.decode "0812"
    assert_equal DateTime, dt.class
    assert_equal 2008, dt.year
    assert_equal 12, dt.month

    assert_raise(ISO8583Exception) {
      dt = YYMMCodec.decode "0913"
    }

    assert_raise(ISO8583Exception) {
      dt = YYMMCodec.encode "0913"
    }

    assert_equal "0912", YYMMCodec.encode("0912")
  end

  def test_A_Codec
    assert_raise(ISO8583Exception) {
      A_Codec.encode "!!!"
    }
    assert_equal "bla", AN_Codec.encode("bla")
    assert_equal "bla", AN_Codec.decode("bla")
  end

  def test_AN_Codec
    assert_raise(ISO8583Exception) {
      AN_Codec.encode "!!!"
    }
    assert_equal "bla", AN_Codec.encode("bla")
    assert_equal "bla", AN_Codec.decode("bla")
  end

  def test_Track2_Codec
    assert_raise(ISO8583Exception) {
      Track2.encode "!!!"
    }
    assert_raise(ISO8583Exception) {
      Track2.encode ";12312312=123?5"
    }
    assert_equal ";123123123=123?5", Track2.encode(";123123123=123?5")
    assert_equal ";123123123=123?5", Track2.decode(";123123123=123?5")
  end

  def test_packed_codec
    assert_equal "\x12", Packed_Number.encode(12)
    assert_equal "\x12", Packed_Number.encode("12")
    assert_equal "\x02", Packed_Number.encode("2")
    assert_equal "\x02", Packed_Number.encode(2)
    assert_equal "\x02\x55", Packed_Number.encode(0xff)
    assert_raise(ISO8583Exception) {
      Packed_Number.encode ";12312312=123?5"
    }
    assert_raise(ISO8583Exception) {
      Packed_Number.encode "F"
    }
  end

  def test_ebcdic_codec
    assert_equal "\xf0\xf1\xf2\xf3\xf4".force_encoding('ASCII-8BIT'), EBCDIC_Codec.encode('01234')
    assert_equal "01", EBCDIC_Codec.decode("\xf0\xf1")
    assert_equal 123, EBCDIC_Length_Codec.decode("\xf1\xf2\xf3")
  end

  def test_binary_codec
    assert_equal "\x124", Binary_Codec.encode('1234')
    assert_equal '1234', Binary_Codec.decode("\x124")
  end

  def test_F60_Codec
    assert_equal "003512", F60_Codec.encode({ recurring_payment_indicator: '2' }, '')
    result = { recurring_payment_indicator: '2' }
    assert_equal result, F60_Codec.decode('003512', '')

    assert_equal "003301", F60_Codec.encode({ cvv2_presence_indicator: '1' }, '')
    result = { cvv2_presence_indicator: '1' }
    assert_equal result, F60_Codec.decode('003301', '')

    assert_equal "0073512345", F60_Codec.encode({ merchant_post_code: '12345' }, '')
    result = { merchant_post_code: '12345' }
    assert_equal result, F60_Codec.decode('0073512345', '')

    assert_equal "0313712345678901234567890123456789", F60_Codec.encode({ dynamic_currency_conversion_data: '12345678901234567890123456789' }, '')
    result = { dynamic_currency_conversion_data: '12345678901234567890123456789' }
    assert_equal result, F60_Codec.decode('0313712345678901234567890123456789', '')

    assert_equal "0044007", F60_Codec.encode({ electronic_commerce_indicator: '07' }, '')
    result = { electronic_commerce_indicator: '07' }
    assert_equal result, F60_Codec.decode('0044007', '')

    assert_equal "0045202", F60_Codec.encode({ recurring_payment_response: '02' }, '')
    result = { recurring_payment_response: '02', "recurring_payment_response_value2text"=>"Try again later" }
    assert_equal result, F60_Codec.decode('0045202', '')

    assert_equal "00553128", F60_Codec.encode({ terminal_capabilities: '128' }, '')
    result = { terminal_capabilities: '128' }
    assert_equal result, F60_Codec.decode('00553128', '')

    assert_equal "04261MDAwMDAwMDAwMDAxNTQQQNTMDAaAwMDzODgyNFg=", F60_Codec.encode({ xid: 'MDAwMDAwMDAwMDAxNTQQQNTMDAaAwMDzODgyNFg=' }, '')
    result = { xid: 'MDAwMDAwMDAwMDAxNTQQQNTMDAaAwMDzODgyNFg=' }
    assert_equal result, F60_Codec.decode('04261MDAwMDAwMDAwMDAxNTQQQNTMDAaAwMDzODgyNFg=', '')

    assert_equal "04262MDAwMDAwMDAwMDAxNTQQQNTMDAaAwMDzODgyNFg=", F60_Codec.encode({ cavv: 'MDAwMDAwMDAwMDAxNTQQQNTMDAaAwMDzODgyNFg=' }, '')
    result = { cavv: 'MDAwMDAwMDAwMDAxNTQQQNTMDAaAwMDzODgyNFg=' }
    assert_equal result, F60_Codec.decode('04262MDAwMDAwMDAwMDAxNTQQQNTMDAaAwMDzODgyNFg=', '')

    assert_equal "04263MDAwMDAwMDAwMDAxNTQQQNTMDAaAwMDzODgyNFg=", F60_Codec.encode({ ucaf: 'MDAwMDAwMDAwMDAxNTQQQNTMDAaAwMDzODgyNFg=' }, '')
    result = { ucaf: 'MDAwMDAwMDAwMDAxNTQQQNTMDAaAwMDzODgyNFg=' }
    assert_equal result, F60_Codec.decode('04263MDAwMDAwMDAwMDAxNTQQQNTMDAaAwMDzODgyNFg=', '')

    assert_equal "00864123456", F60_Codec.encode({ mastercard_assigned_id: '123456' }, '')
    result = { mastercard_assigned_id: '123456' }
    assert_equal result, F60_Codec.decode('00864123456', '')

    assert_equal "0166512345678901234", F60_Codec.encode({ ewallet_data: '12345678901234' }, '')
    result = { ewallet_data: '12345678901234' }
    assert_equal result, F60_Codec.decode('0166512345678901234', '')
  end
end
