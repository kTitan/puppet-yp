require 'spec_helper_acceptance'

describe 'yp::bind' do

  it 'should work with no errors' do

    pp = <<-EOS
      include ::portmap

      class { '::yp':
        domain => 'example.com',
      }

      class { '::yp::bind':
        domain  => 'example.com',
        servers => ['#{ENV["BODGIT_YP_SERV_SERVER"]}'],
      }

      Class['::portmap'] ~> Class['::yp::bind'] <~ Class['::yp']
    EOS

    apply_manifest(pp, :catch_failures => true)
    apply_manifest(pp, :catch_changes  => true)
  end

  case fact('osfamily')
  when 'OpenBSD'
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
  when 'RedHat'
    describe file('/etc/yp.conf') do
      it { should be_file }
      it { should be_mode 644 }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
      its(:content) { should match /^ypserver\s+#{ENV["BODGIT_YP_SERV_SERVER"]}$/ }
    end

    describe file('/etc/pam.d/system-auth-ac') do
      it { should be_file }
      it { should be_mode 644 }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
      its(:content) { should match /^password\s+sufficient\s+pam_unix.so\s+md5\s+shadow\s+nis\s+nullok\s+try_first_pass\s+use_authtok$/ }
    end

    describe file('/etc/nsswitch.conf') do
      it { should be_file }
      it { should be_mode 644 }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
      its(:content) { should match /^passwd:\s+files\s+nis\s+sss$/ }
      its(:content) { should match /^shadow:\s+files\s+nis\s+sss$/ }
      its(:content) { should match /^group:\s+files\s+nis\s+sss$/ }
      its(:content) { should match /^hosts:\s+files\s+nis\s+dns$/ }
      its(:content) { should match /^netgroup:\s+files\s+nis\s+sss$/ }
      its(:content) { should match /^automount:\s+files\s+nis$/ }
    end
  end

  describe service('ypbind') do
    it { should be_enabled }
    it { should be_running }
  end

  describe command('rpcinfo -p') do
    its(:exit_status) { should eq 0 }
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
end
