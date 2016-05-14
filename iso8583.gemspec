# -*- mode: ruby; encoding: utf-8; tab-width: 2; indent-tabs-mode: nil -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'iso8583/version'
 
Gem::Specification.new do |s|
  s.name        = 'iso8583'
  s.version     = ISO8583::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Tim Becker', 'Slava Kravchenko', 'Emil Petkov']
  s.email       = ['tim.becker@kuriositaet.de','cordawyn@gmail.com', 'emil_5kov@yahoo.com']
  s.homepage    = 'http://github.com/emerchantpay/8583/'
  s.summary     = 'Ruby implementation of ISO 8583 financial messaging'
  s.description = 'Ruby implementation of ISO 8583 financial messaging'
 
  s.required_rubygems_version = '>= 1.3.6'
  s.rubyforge_project         = 'iso8583'
  s.has_rdoc                  = true
  
  s.requirements << 'none'
  
  s.files        = Dir.glob("{lib,test}/**/*") + %w(AUTHORS CHANGELOG LICENSE README TODO)
  s.require_path = 'lib'
end
