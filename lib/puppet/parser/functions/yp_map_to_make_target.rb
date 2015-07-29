#
# yp_map_to_make_target.rb
#

module Puppet::Parser::Functions
  newfunction(:yp_map_to_make_target, :type => :rvalue, :doc => <<-EOS
Transforms a YP map name to the corresponding make target.

*Example:*

    yp_map_to_make_target(['group.byname', 'group.bygid'])
    yp_map_to_make_target('passwd.byname')

Would result in:

    ['group']
    'passwd'
    EOS
  ) do |arguments|

    raise(Puppet::ParserError, 'yp_map_to_make_target(): Wrong number of ' +
      "arguments given (#{arguments.size} for 1)") if arguments.size < 1

    item = arguments[0]

    unless item.is_a?(Array) or item.is_a?(String)
      raise(Puppet::ParseError, 'yp_map_to_make_target(): Requires array or ' +
        'string to work with')
    end

    gsubs = {
      /^master\.passwd\./                  => 'passwd.',
      /(?:\.by[a-z]+|(?<=mail)\.aliases)$/ => '',
    }

    case lookupvar('osfamily')
    when 'OpenBSD'
      gsubs[/^mail$/] = 'aliases'
    when 'RedHat'
      gsubs[/^netgroup$/] = 'netgrp'
    end

    if item.is_a?(Array)
      return item.collect { |x|
        gsubs.inject(x) do |s, m|
          s.gsub(*m)
        end
      }.uniq
    else
      return gsubs.inject(item) do |s, m|
        s.gsub(*m)
      end
    end
  end
end

# vim: set ts=2 sw=2 et :
