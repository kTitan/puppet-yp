require 'spec_helper_acceptance'

describe 'yp' do

  it 'should work with no errors' do

    pp = <<-EOS
      class { '::yp':
        domain => 'example.com',
      }
    EOS

    apply_manifest(pp, :catch_failures => true)
    apply_manifest(pp, :catch_changes  => true)
  end

  case fact('osfamily')
  when 'OpenBSD'
    describe file('/etc/defaultdomain') do
      it { should be_file }
      it { should be_mode 644 }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'wheel' }
      its(:content) { should eq "example.com\n" }
    end
  when 'RedHat'
    describe file('/etc/sysconfig/network') do
      it { should be_file }
      it { should be_mode 644 }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
      its(:content) { should match /^NISDOMAIN=example.com$/ }
    end
  end

  describe command('domainname') do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should eq "example.com\n" }
  end
end
