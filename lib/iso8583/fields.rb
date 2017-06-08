#--
# Copyright 2009 by Tim Becker (tim.becker@kuriostaet.de)
# MIT License, for details, see the LICENSE file accompaning
# this distribution
#++

module ISO8583

  # This file contains a number of preinstantiated Field definitions. You
  # will probably need to create own fields in your implementation, please
  # see Field and Codec for further discussion on how to do this.
  # The fields currently available are those necessary to implement the 
  # Berlin Groups Authorization Spec.
  #
  # The following fields are available:
  #
  # [+LL+]                    special form to de/encode variable length indicators, two bytes ASCII numerals
  # [+LLL+]                   special form to de/encode variable length indicators, two bytes ASCII numerals
  # [+LL_BCD+]                special form to de/encode variable length indicators, two BCD digits
  # [+LLVAR_N+]               two byte variable length ASCII numeral, payload ASCII numerals
  # [+LLLVAR_N+]              three byte variable length ASCII numeral, payload ASCII numerals
  # [+LLVAR_Z+]               two byte variable length ASCII numeral, payload Track2 data
  # [+LLVAR_AN+]              two byte variable length ASCII numeral, payload ASCII
  # [+LLVAR_ANS+]             two byte variable length ASCII numeral, payload ASCII+special
  # [+LLLVAR_AN+]             three byte variable length ASCII numeral, payload ASCII
  # [+LLLVAR_ANS+]            three byte variable length ASCII numeral, payload ASCII+special
  # [+LLVAR_B+]               Two byte variable length binary payload
  # [+LLLVAR_B+]              Three byte variable length binary payload
  # [+A+]                     fixed length letters, represented in ASCII
  # [+N+]                     fixed lengh numerals, repesented in ASCII, padding right justified using zeros
  # [+AN+]                    fixed lengh ASCII [A-Za-z0-9], padding left justified using spaces.
  # [+ANP+]                   fixed lengh ASCII [A-Za-z0-9] and space, padding left, spaces
  # [+ANS+]                   fixed length ASCII  [\x20-\x7E], padding left, spaces
  # [+B+]                     binary data, padding left using nulls (0x00)
  # [+MMDDhhmmss+]            Date, formatted as described in ASCII numerals
  # [+YYMMDDhhmmss+]          Date, formatted as named in ASCII numerals
  # [+YYMM+]                  Expiration Date, formatted as named in ASCII numerals
  # [+LL_EBCDIC+]             two byte variable length EBCDIC encoded
  # [+LLL_EBCDIC+]            three byte variable length EBCDIC encoded
  # [+LL_EBCDIC_BCD+]         two bytes EBCDIC length, payload in BCD
  # [+LLL_EBCDIC_BCD+]        three bytes EBCDIC length, payload in BCD
  # [+EBCDIC_AN+]             no length prefix, payload is alphanumerical, encoded in EBCDIC
  # [+LL_EBCDIC_ANS+]         two bytes EBCDIC length, payload is alphanumerical + special characters, encoded in EBCDIC
  # [+LLL_EBCDIC_ANS+]        three bytes EBCDIC length, payload is alphanumerical + special characters, encoded in EBCDIC
  # This is used only for BMP 57 of Paynetics Integration
  # [+LLL_EBCDIC_ANS_SUFFIX+] three bytes EBCDIC length, payload is alphanumerical + special characters, encoded in EBCDIC + suffix, encoded in 2 bytes BCD.
  # [+LLL_SUBFIELD_EBCDIC+]   three bytes EBCDIC length, payload is specific for each field. Used only for subfields BMP 60
  # [+LL_EBCDIC_ANS_44+]      two bytes EBCDIC length, payload ASCII+special. Used for field 44


  PADDING_LEFT_JUSTIFIED_SPACES = lambda {|val, len|
    sprintf "%-#{len}s", val
  }

  PADDING_LEFT_JUSTIFIED_ZEROS = -> (value, len) do
    ebcdic_zero = "\xF0"
    if value.length < len
      len_prefix = ""
      (len - value.length).times { len_prefix << ebcdic_zero}
      len_prefix.force_encoding('ASCII-8BIT') + value
    else
      value
    end
  end

  PADDING_LEFT_JUSTIFIED_ZEROS_STRICT = -> (value) do
    ebcdic_zero = "\xF0"
    len = 8
    if value.length < len
      len_prefix = ""
      (len - value.length).times { len_prefix << ebcdic_zero}
      len_prefix.force_encoding('ASCII-8BIT') + value
    else
      value
    end
  end

  ## Length encodings
  # Special form to de/encode variable length indicators, two bytes ASCII numerals
  LL         = Field.new
  LL.name    = "LL"
  LL.length  = 2
  LL.codec   = ASCII_Number
  LL.padding = lambda {|value|
    sprintf("%02d", value)
  }
  # Special form to de/encode variable length indicators, three bytes ASCII numerals
  LLL         = Field.new
  LLL.name    = "LLL"
  LLL.length  = 3
  LLL.codec   = ASCII_Number
  LLL.padding = lambda {|value|
    sprintf("%03d", value)
  }

  # Special form to de/encode variable length indicators, two byte variable length EBCDIC encoded
  LL_EBCDIC  = Field.new
  LL_EBCDIC.length = 2
  LL_EBCDIC.codec = EBCDIC_Length_Codec
  LL_EBCDIC.padding = PADDING_LEFT_JUSTIFIED_ZEROS

  # Special form to de/encode variable length indicators, three byte variable length EBCDIC encoded
  LLL_EBCDIC = Field.new
  LLL_EBCDIC.length = 3
  LLL_EBCDIC.codec = EBCDIC_Length_Codec
  LLL_EBCDIC.padding = PADDING_LEFT_JUSTIFIED_ZEROS


  LL_BCD        = BCDField.new
  LL_BCD.length = 2
  LL_BCD.codec  = Packed_Number
  ##Length encoding

  # Two byte variable length ASCII numeral, payload ASCII numerals
  LLVAR_N        = Field.new
  LLVAR_N.length = LL
  LLVAR_N.codec  = ASCII_Number

  # Three byte variable length ASCII numeral, payload ASCII numerals
  LLLVAR_N        = Field.new
  LLLVAR_N.length = LLL
  LLLVAR_N.codec  = ASCII_Number

  # Two byte variable length ASCII numeral, payload Track2 data
  LLVAR_Z         = Field.new
  LLVAR_Z.length  = LL
  LLVAR_Z.codec   = Track2

  # Two byte variable length ASCII numeral, payload ASCII, fixed length, zeropadded (right)
  LLVAR_AN        = Field.new
  LLVAR_AN.length = LL
  LLVAR_AN.codec  = AN_Codec

  # Two byte variable length ASCII numeral, payload ASCII+special
  LLVAR_ANS        = Field.new
  LLVAR_ANS.length = LL
  LLVAR_ANS.codec  = ANS_Codec

  # Three byte variable length ASCII numeral, payload ASCII, fixed length, zeropadded (right)
  LLLVAR_AN        = Field.new
  LLLVAR_AN.length = LLL
  LLLVAR_AN.codec  = AN_Codec

  # Three byte variable length ASCII numeral, payload ASCII+special
  LLLVAR_ANS        = Field.new
  LLLVAR_ANS.length = LLL
  LLLVAR_ANS.codec  = ANS_Codec

  # Two byte variable length binary payload
  LLVAR_B        = Field.new
  LLVAR_B.length = LL
  LLVAR_B.codec  = Null_Codec


  # Three byte variable length binary payload
  LLLVAR_B        = Field.new
  LLLVAR_B.length = LLL
  LLLVAR_B.codec  = Null_Codec

  # Fixed lengh numerals, repesented in ASCII, padding right justified using zeros
  N = Field.new
  N.codec = ASCII_Number
  N.padding = lambda {|val, len|
    sprintf("%0#{len}d", val)
  }

  N_BCD = BCDField.new
  N_BCD.codec = Packed_Number

  # Fixed length ASCII letters [A-Za-z]
  A = Field.new
  A.codec = A_Codec

  # Fixed lengh ASCII [A-Za-z0-9], padding left justified using spaces.
  AN = Field.new
  AN.codec = AN_Codec
  AN.padding = PADDING_LEFT_JUSTIFIED_SPACES

  # Fixed lengh ASCII [A-Za-z0-9] and space, padding left, spaces
  ANP = Field.new
  ANP.codec = ANP_Codec
  ANP.padding = PADDING_LEFT_JUSTIFIED_SPACES

  # Fixed length ASCII  [\x20-\x7E], padding left, spaces
  ANS = Field.new
  ANS.codec = ANS_Codec
  ANS.padding = PADDING_LEFT_JUSTIFIED_SPACES

  # Binary data, padding left using nulls (0x00)
  B = Field.new
  B.codec = Null_Codec
  B.padding = lambda {|val, len|
    while val.length < len
      val = val + "\000"
    end
    val
  }

  # Date, formatted as described in ASCII numerals
  MMDDhhmmss        = Field.new
  MMDDhhmmss.codec  = MMDDhhmmssCodec
  MMDDhhmmss.length = 10

  #Date, formatted as described in ASCII numerals
  YYMMDDhhmmss        = Field.new
  YYMMDDhhmmss.codec  = YYMMDDhhmmssCodec
  YYMMDDhhmmss.length = 12

  #Date, formatted as described in ASCII numerals
  YYMM        = Field.new
  YYMM.codec  = YYMMCodec
  YYMM.length = 4

  # fields patch
  HHMMSS        = Field.new
  HHMMSS.codec  = HHMMSSCodec
  HHMMSS.length = 4

  MMDD        = Field.new
  MMDD.codec  = MMDDCodec
  MMDD.length = 4

  Field44        = Field.new
  Field44.length = LL
  Field44.codec  = F44_Codec
  Field44.extended_arguments = true

  Field60        = Field.new
  Field60.length = LLL
  Field60.codec  = F60_Codec
  Field60.extended_arguments = true

  Field61        = Field.new
  Field61.length = LLL
  Field61.codec  = F61_Codec
  Field61.extended_arguments = true

  Field62        = Field.new
  Field62.length = LLL
  Field62.codec  = F62_Codec
  Field62.extended_arguments = true

  # Although the payload is BCD we probably do not want to use the BCDField class,
  # as it relies on a Fixnum being provided as a length. It is effective for LL_BCD field,
  # however when you need to encode the length in a different encoding this causes problems

  # 2 bytes EBCDIC length, payload in BCD, odd requirement
  # Appends a HEX "F" to the payload. Cannot be used with
  # the next codec, although they seem close
 # LL_EBCDIC_BCD = Field.new
 # LL_EBCDIC_BCD.length = LL_EBCDIC
 # LL_EBCDIC_BCD.codec = Packed_Number
 # LL_EBCDIC_BCD.odd_requirement = true

  # 2 bytes EBCDIC length, payload in BCD, regular
  LL_EBCDIC_BCD = Field.new
  LL_EBCDIC_BCD.length = LL_EBCDIC
  LL_EBCDIC_BCD.codec = Packed_Number
  LL_EBCDIC_BCD.odd_requirement = true

  # 3 bytes EBCDIC length, payload in BCD
  LLL_EBCDIC_BCD = Field.new
  LLL_EBCDIC_BCD.length = LLL_EBCDIC
  LLL_EBCDIC_BCD.codec = Packed_Number

  # alphanumerical payload in EBCDIC, no length prefix
  EBCDIC_AN = Field.new
  EBCDIC_AN.codec = EBCDIC_Codec
  EBCDIC_AN.padding = PADDING_LEFT_JUSTIFIED_SPACES

  # 3 bytes EBCDIC length, payload in EBCDIC
  LLL_EBCDIC_ANS = Field.new
  LLL_EBCDIC_ANS.length = LLL_EBCDIC
  LLL_EBCDIC_ANS.codec = EBCDIC_Codec

  # 2 bytes EBCDIC length, payload in EBCDIC
  LL_EBCDIC_ANS = Field.new
  LL_EBCDIC_ANS.length = LL_EBCDIC
  LL_EBCDIC_ANS.codec = EBCDIC_Codec

  # 2 bytes EBCDIC length, payload in ASCII, special use case for Paynetics field 44
  LL_EBCDIC_ANS_44 = Field.new
  LL_EBCDIC_ANS_44.length = LL_EBCDIC
  LL_EBCDIC_ANS_44.codec = ANS_Codec

  # 3 bytes EBCDIC length, payload in EBCDIC, suffix in BCD
  LLL_EBCDIC_ANS_SUFFIX = Field.new
  LLL_EBCDIC_ANS_SUFFIX.length = LLL_EBCDIC
  LLL_EBCDIC_ANS_SUFFIX.codec = EBCDIC_Codec
  LLL_EBCDIC_ANS_SUFFIX.suffix = LL_BCD
  LLL_EBCDIC_ANS_SUFFIX.padding = PADDING_LEFT_JUSTIFIED_ZEROS_STRICT

  # 3 bytes EBCDIC length, subfield
  LLL_SUBFIELD_EBCDIC = Field.new
  LLL_SUBFIELD_EBCDIC.length = LLL_EBCDIC
  LLL_SUBFIELD_EBCDIC.codec = Subfield_Ebcdic_Codec

end
