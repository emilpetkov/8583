$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

module ISO8583
  require "iso8583/field"
  require "iso8583/codec"
  require "iso8583/subfield_utils"
  require "iso8583/subfield_classes"
  require "iso8583/subfield_bm44"
  require "iso8583/subfield_bm60"
  require "iso8583/subfield_bm62"
  require "iso8583/fields"
  require "iso8583/exception"
  require "iso8583/bitmap"
  require "iso8583/message"
  require "iso8583/util"
end
