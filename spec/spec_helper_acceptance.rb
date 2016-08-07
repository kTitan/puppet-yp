require 'beaker-rspec/spec_helper'
require 'beaker-rspec/helpers/serverspec'

unless ENV['BODGIT_YP_LDAP_SERVER'] and ENV['BODGIT_YP_SERV_SERVER']
  raise 'Need to set environment variables'
end

hosts.each do |host|
  install_puppet
end

RSpec.configure do |c|
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  c.formatter = :documentation

  c.before :suite do
    hosts.each do |host|
      copy_module_to(host, :source => proj_root, :module_name => 'yp')
      on host, puppet('module', 'install', 'bodgit-portmap'),                   { :acceptable_exit_codes => [0,1] }
      on host, puppet('module', 'install', 'puppetlabs-stdlib'),                { :acceptable_exit_codes => [0,1] }
      on host, puppet('module', 'install', 'bodgit-bodgitlib'),                 { :acceptable_exit_codes => [0,1] }
      on host, puppet('module', 'install', 'trlinkin-nsswitch'),                { :acceptable_exit_codes => [0,1] }
      on host, puppet('module', 'install', 'herculesteam-augeasproviders_pam'), { :acceptable_exit_codes => [0,1] }
    end
  end
end
