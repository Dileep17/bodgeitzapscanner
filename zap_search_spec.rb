require 'owasp_zap'
include OwaspZap
require 'selenium-webdriver'
require 'pry'
require 'rest_client'
require 'json'

describe 'test' do
  it 'again' do

    zap  = Zap.new :base => 'http://localhost:8085',
                :target=> 'http://192.168.99.113:8080/bodgeit',
                :output=> 'logfile.txt',
                :zap => '/Applications/OWASP\ ZAP.app/Contents/MacOS/OWASP\ ZAP.sh'

    zap.start :daemon=>true
    p 'Starting ZAP'
    # Wait for ZAP to start
    until zap.running?
      sleep(2)
    end

    profile = Selenium::WebDriver::Firefox::Profile.new
    profile["network.proxy.type"] = 1
    profile["network.proxy.http"] = 'localhost'
    profile["network.proxy.http_port"] = 8085
    profile['network.proxy.no_proxies_on'] = ''
    driver = Selenium::WebDriver.for :firefox, :profile => profile

    driver.navigate.to 'http://192.168.99.113:8080/bodgeit'
    driver.find_element(:link, 'Search').click
    driver.find_element(:name, 'q').send_keys 'Gizmos'
    driver.find_element(:css, "[value='Search']").click
    driver.quit

    p 'Starting Active Scan...'
    scan = zap.ascan # Obtaining the Attack from zap instance
    scan.start
    sleep(2)

    # Wait for the active scan to finish
    while scan.running?
      sleep(2)
    end

    File.open("#{__dir__}/html_report.html",'w') {|f| f.write(zap.html_report)}

    zap.shutdown
  end

end

