require 'spec_helper_acceptance'

describe 'yp::ldap' do

  pp = <<-EOS
    include ::portmap

    class { '::yp::ldap':
      base_dn => 'dc=example,dc=com',
      bind_dn => 'uid=test,ou=people,dc=example,dc=com',
      bind_pw => 'password',
      domain  => 'example.com',
      server  => '#{ENV["BODGIT_YP_LDAP_SERVER"]}',
    }

    class { '::yp':
      domain => 'example.com',
    }

    class { '::yp::bind':
      domain => 'example.com',
    }

    Class['::portmap'] ~> Class['::yp::ldap'] ~> Class['::yp::bind'] <~ Class['::yp']
  EOS

  case fact('osfamily')
  when 'OpenBSD'
    it 'should work with no errors' do
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes  => true)
    end

    describe file('/etc/ypldap.conf') do
      it { should be_file }
      it { should be_mode 640 }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'wheel' }
      #its(:content) { should eq ... }
    end

    describe service('ypldap') do
      it { should be_running }
    end

    describe file('/etc/master.passwd') do
      it { should be_file }
      it { should be_mode 600 }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'wheel' }
      its(:content) { should match /^\+:\*::::::::$/ }
      its(:content) { should_not match /^test:/ }
    end

    describe file('/etc/passwd') do
      it { should be_file }
      it { should be_mode 644 }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'wheel' }
      its(:content) { should match /^\+:\*:0:0:::$/ }
      its(:content) { should_not match /^test:/ }
    end

    describe file('/etc/group') do
      it { should be_file }
      it { should be_mode 644 }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'wheel' }
      its(:content) { should match /^\+:\*::$/ }
      its(:content) { should_not match /^test:/ }
    end

    describe file('/etc/defaultdomain') do
      it { should be_file }
      it { should be_mode 644 }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'wheel' }
      its(:content) { should eq "example.com\n" }
    end

    describe command('domainname') do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should eq "example.com\n" }
    end

    describe service('ypbind') do
      it { should be_enabled }
      it { should be_running }
    end

    describe command('rpcinfo -p') do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match /100004\s+2\s+tcp\s+\d+\s+ypserv/ }
      its(:stdout) { should match /100004\s+2\s+udp\s+\d+\s+ypserv/ }
      its(:stdout) { should match /100007\s+2\s+tcp\s+\d+\s+ypbind/ }
      its(:stdout) { should match /100007\s+2\s+udp\s+\d+\s+ypbind/ }
    end

    describe group('test') do
      it { should exist }
      it { should have_gid 2000 }
    end

    describe user('test') do
      it { should exist }
      it { should belong_to_group 'test' }
      it { should have_uid 2000 }
      it { should have_home_directory '/home/test' }
      it { should have_login_shell '/bin/bash' }
    end
  else
    it 'should not work' do
      apply_manifest(pp, :expect_failures => true)
    end
  end
end
