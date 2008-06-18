require File.expand_path('../test_helper', __FILE__)
require 'config_uninstaller'

describe "ConfigUninstaller" do
  before do
    @tmp = File.expand_path('../tmp')
    FileUtils.mkdir_p @tmp
    @config_installer = File.expand_path('../../config_uninstaller.rb', __FILE__)
    
    @host = "het-manfreds-blog.local"
    @vhost_file = File.join(@tmp, 'test.vhost.conf')
    
    File.open(@vhost_file, 'w') { |f| f << 'bla' }
    
    @uninstaller = ConfigUninstaller.new([{ 'config_path' => @vhost_file, 'host' => @host}].to_yaml)
  end
  
  it "should initialize" do
    @uninstaller.data.should == [{ 'config_path' => @vhost_file, 'host' => @host }]
  end
  
  it "should remove the entry from the hosts db" do
    @uninstaller.expects(:system).with("/usr/bin/dscl localhost -delete /Local/Default/Hosts/het-manfreds-blog.local")
    @uninstaller.remove_from_hosts(0)
  end
  
  it "should remove the vhost config file" do
    @uninstaller.remove_vhost_conf(0)
    File.should.not.exist @vhost_file
  end
  
  it "should restart Apache" do
    @uninstaller.expects(:system).with("/bin/launchctl stop org.apache.httpd")
    @uninstaller.restart_apache!
  end
  
  it "should remove multiple applications in one go" do
    uninstaller = ConfigUninstaller.any_instance
    
    uninstaller.expects(:remove_from_hosts).with(0)
    uninstaller.expects(:remove_from_hosts).with(1)
    
    uninstaller.expects(:remove_vhost_conf).with(0)
    uninstaller.expects(:remove_vhost_conf).with(1)
    
    uninstaller.expects(:restart_apache!)
    
    ConfigUninstaller.new([{}, {}].to_yaml).uninstall!
  end
end