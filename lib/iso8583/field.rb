require 'byebug'
module ISO8583

  class Field
    # may either be some other Field in which the length is encoded or a Fixnum for
    # fixed length fields. Length should always be the length of the *encoded* value.
    # A 6 digit BCD field will require a length 3, as will a 5 digit BCD field.
    # The subclass BCDField handles this to keep things consistant.
    attr_accessor :length,
                  :codec,
                  :padding,
                  :max,
                  :extended_arguments,
                  :suffix,
                  :suffix_value,
                  :odd_requirement

    attr_writer   :name
    attr_accessor :bmp

    def name
      "BMP #{bmp}: #{@name}"
    end

    def parse(raw, message)
      real_value, rest, _raw_value = parse_ex(raw, message)
      [ real_value, rest ]
    end

    def parse_ex(raw, message)
      len, raw = case length
                 when Fixnum
                   [length, raw]
                 when Field
                   length.parse(raw, message)
                 else
                   raise ISO8583Exception.new("Cannot determine the length of '#{name}' field")
                 end
      raw_value = raw[0,len]
      # make sure we have enough data ...
      if raw_value.length != len
        mes = "Field has incorrect length! field: #{raw_value} len/expected: #{raw_value.length}/#{len}; Field name is '#{name}'"
        raise ISO8583ParseException.new(mes)
      end
      rest = raw[len, raw.length]
      begin
        real_value = codec.decode(raw_value, extended_arguments ? message : nil)
#      rescue
#        raise ISO8583ParseException.new($!.message+" (#{name})")
      end

      [real_value, rest, raw_value]
    end


    # Encoding needs to consider length representation, the actual encoding (such as charset or BCD) 
    # and padding. 
    # The order may be important! This impl calls codec.encode and then pads, in case you need the other 
    # special treatment, you may need to override this method alltogether.
    # In other cases, the padding has to be implemented by the codec, such as BCD with an odd number of nibbles.
    def encode(value, message)
      if( extended_arguments )
        encoded_value = codec.encode(value, message)
      else
        encoded_value = codec.encode(value)
      end

      if padding
        if padding.arity == 1
          encoded_value = padding.call(encoded_value)
        elsif padding.arity == 2
          encoded_value = padding.call(encoded_value, length)
        end
      end

      # We are using the suffix for only one field at the moment:
      # Paynetics BMP 57, Sequence Generation Number. Actually we are not
      # using it for any purpose, but it is a requirement.
      if suffix
        encoded_value = encoded_value + suffix.encode(suffix_value, message)
      end

      if( encoded_value == nil )
        puts "\n\n\nencoded_value == nil for value = #{value}\n\n\n"
      end

      len_str = case length
                when Fixnum
                  raise ISO8583Exception.new("Too long: #{value} (#{name})! length=#{length}")  if encoded_value.length > length
                  raise ISO8583Exception.new("Too short: #{value} (#{name})! length=#{length}") if encoded_value.length < length
                  "".force_encoding('ASCII-8BIT')
                when Field
                  raise ISO8583Exception.new("Max lenth exceeded: #{value}, max: #{max}") if max && encoded_value.length > max
                  length.encode(encoded_value.length, message)
                else
                  raise ISO8583Exception.new("Invalid length (#{length}) for '#{name}' field")
                end

      # Trailing HEX F
      # It needs to be added after the length encoding because it should not be
      # part of the length calculation. This is why it cannot be a part of any codec
      if odd?(value)
        encoded_value = add_trailing_hex_for(encoded_value)
      end

      len_str + encoded_value
    end

    private

    def odd?(value)
      odd_requirement && value.length % 2 != 0
    end

    def add_trailing_hex_for(encoded_value)
      bytes = encoded_value.unpack("c*")
      last_byte = bytes.pop
      last_byte |= 0xF
      bytes << last_byte
      bytes.pack("c*")
      #new_encoded_value
    end
  end

  class BCDField < Field
    # This corrects the length for BCD fields, as their encoded length is half (+ parity) of the
    # content length. E.g. 123 (length = 3) encodes to "\x01\x23" (length 2)
    def length
      _length = super
      # I suppose there wasn't a case in which the length for a BCD field could be a new codec.
      # This is a necessary check, otherways (length % 2) raises an error. So in this case length will
      # be a Field object, not a Fixnum
      # This is something else, this is the length of the field length!!!
      # _length = _length.respond_to?(:length) ? _length.length : _length
      # Need to find a way to return the Field itself
      _length = _length.respond_to?(:length) ? _length.length : _length
      (_length % 2) != 0 ? (_length / 2) + 1 : _length / 2
    end
  end
end
