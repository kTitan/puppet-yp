require 'spec_helper_acceptance'

describe 'yp::serv' do

  case fact('osfamily')
  when 'OpenBSD'
    group         = 'wheel'
    makedbm       = '/usr/sbin/makedbm'
    maps          = %w(passwd.byname passwd.byuid master.passwd.byname master.passwd.byuid group.byname group.bygid hosts.byname hosts.byaddr networks.byname networks.byaddr rpc.bynumber services.byname protocols.byname protocols.bynumber netid.byname mail.aliases mail.byaddr)
    map_extension = '.db'
    shell         = '/bin/ksh'
    targets       = %w(passwd group hosts networks rpc services protocols netid aliases)
  when 'RedHat'
    group         = 'root'
    makedbm       = fact('architecture') == 'x86_64' ? '/usr/lib64/yp/makedbm' : '/usr/lib/yp/makedbm'
    maps          = %w(passwd.byname passwd.byuid group.bygid group.byname hosts.byaddr hosts.byname rpc.byname rpc.bynumber services.byname services.byservicename netid.byname protocols.byname protocols.bynumber mail.aliases)
    map_extension = ''
    shell         = '/bin/bash'
    targets       = %w(passwd group hosts rpc services netid protocols mail)
  end

  it 'should work with no errors' do

    pp = <<-EOS
      include ::portmap

      class { '::yp':
        domain => 'example.com',
      }

      class { '::yp::serv':
        domain => 'example.com',
        maps   => ['#{maps.join("', '")}'],
      }

      Class['::portmap'] ~> Class['::yp::serv'] <- Class['::yp']

      group { 'test':
        ensure => present,
        gid    => 2000,
      }

      user { 'test':
        ensure     => present,
        comment    => 'Test User',
        gid        => 2000,
        home       => '/home/test',
        managehome => true,
        shell      => '#{shell}',
        uid        => 2000,
        before     => Class['::yp::serv'],
      }
    EOS

    apply_manifest(pp, :catch_failures => true)
    apply_manifest(pp, :catch_changes  => true)
  end

  describe service('ypserv') do
    it { should be_running }
  end

  describe service('yppasswdd') do
    it { should be_running }
  end

  describe file('/var/yp') do
    it { should be_directory }
    it { should be_mode 755 }
    it { should be_owned_by 'root' }
    it { should be_grouped_into group }
  end

  describe file('/var/yp/Makefile') do
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by 'root' }
    it { should be_grouped_into group }
    case os[:family]
    when 'openbsd'
      its(:content) { should match /^SUBDIR=example.com$/ }
      its(:content) { should match /^#{targets.join(' ')} :/ }
    when 'redhat'
      its(:content) { should match /^all:  #{targets.join(' ')}$/ }
      its(:content) { should match /^NOPUSH=true$/ }
      its(:content) { should match /^MINUID=1000$/ }
      its(:content) { should match /^MINGID=1000$/ }
      its(:content) { should match /^MERGE_PASSWD=true$/ }
      its(:content) { should match /^MERGE_GROUP=true$/ }
    end
  end

  describe file('/var/yp/example.com') do
    it { should be_directory }
    it { should be_mode 755 }
    it { should be_owned_by 'root' }
    it { should be_grouped_into group }
  end

  describe file('/var/yp/example.com/Makefile'), :if => os[:family] == 'openbsd' do
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by 'root' }
    it { should be_grouped_into group }
    its(:content) { should match /^all: #{targets.join(' ')}$/ }
    its(:content) { should match /^NOPUSH="True"$/ }
    its(:content) { should match /^UNSECURE="True"$/ }
    its(:content) { should match /^MINUID=1000$/ }
    its(:content) { should match /^MINGID=1000$/ }
  end

  describe file('/var/yp/ypservers') do
    its(:content) { should match /^#{fact('hostname')}$/ }
  end

  (maps + %w(ypservers)).each do |m|
    describe file("/var/yp/example.com/#{m}#{map_extension}") do
      it { should be_file }
      it { should be_mode 600 }
      it { should be_owned_by 'root' }
      it { should be_grouped_into group }
      its(:size) { should > 0 }
    end
  end

  targets.each do |t|
    describe file("/var/yp/example.com/#{t}.time"), :if => os[:family] == 'openbsd' do
      it { should be_file }
      it { should be_mode 644 }
      it { should be_owned_by 'root' }
      it { should be_grouped_into group }
      its(:size) { should eq 0 }
    end
  end

  describe file('/etc/defaultdomain'), :if => os[:family] == 'openbsd' do
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by 'root' }
    it { should be_grouped_into group }
    its(:content) { should eq "example.com\n" }
  end

  describe file('/etc/sysconfig/network'), :if => os[:family] == 'redhat' do
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by 'root' }
    it { should be_grouped_into group }
    its(:content) { should match /^NISDOMAIN=example.com$/ }
  end

  describe command('domainname') do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should eq "example.com\n" }
  end

  describe command('rpcinfo -p') do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match /100004\s+2\s+tcp\s+\d+\s+ypserv/ }
    its(:stdout) { should match /100004\s+2\s+udp\s+\d+\s+ypserv/ }
    its(:stdout) { should match /100009\s+1\s+tcp\s+\d+\s+yppasswdd/ } if os[:family] == 'openbsd'
    its(:stdout) { should match /100009\s+1\s+udp\s+\d+\s+yppasswdd/ }
  end

  describe command("#{makedbm} -u /var/yp/example.com/ypservers") do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match /^#{fact('hostname')}\s+#{fact('hostname')}$/ }
  end

  describe command("#{makedbm} -u /var/yp/example.com/passwd.byname") do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match /^test\s+test:[!*]+:2000:2000:Test User:\/home\/test:#{shell}$/ }
  end

  describe command("#{makedbm} -u /var/yp/example.com/passwd.byuid") do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match /^2000\s+test:[!*]+:2000:2000:Test User:\/home\/test:#{shell}$/ }
  end

  describe command("#{makedbm} -u /var/yp/example.com/group.bygid") do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match /^2000\s+test:[!*]:2000:$/ }
  end

  describe command("#{makedbm} -u /var/yp/example.com/group.byname") do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match /^test\s+test:[!*]:2000:$/ }
  end
end
