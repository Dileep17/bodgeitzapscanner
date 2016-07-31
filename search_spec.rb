
# try using zap api directly than using owasp_zap gem!

require 'selenium-webdriver'
require 'owasp_zap'
require 'pry'
require 'rest_client'
require 'json'

include OwaspZap

describe 'User' do

  it 'should be able to search' do
    # open ZAP
    z = Zap.new :base => 'http://localhost:8085',
                :target=> 'http://192.168.99.113:8080/bodgeit',
                :output=> 'logfile.txt',
                :zap => '/Applications/OWASP\ ZAP.app/Contents/MacOS/OWASP\ ZAP.sh'

    # start ZAP in deamon mode
    z.start :daemon => true
    sleep 5 # wait for zap proxy to load
    # set firefox proxy to be ZAP proxy
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

    wait_for_pscan_to_complete

    # run active scan
    active_scan

    # generate report
    html_report

    #shutdown zap
    z.shutdown
  end

  def active_scan
    # run active scanner
    scan = RestClient::get 'http://localhost:8085/JSON/ascan/action/scan/',
                           :params => { :zapapiformat => 'JSON',
                                        :url => 'http://192.168.99.113:8080/bodgeit' ,
                                        :recurse => 'True', :inScopeOnly => 'False' }

    #wait for active scanner to complete
    until JSON.parse(scan)["status"] != '100'
      puts 'waiting for scan to complete.!'
    end
  end

  def html_report
    sleep 3
    content = RestClient::get 'http://localhost:8085/OTHER/core/other/htmlreport/'
    File.open("#{__dir__}/html_report.html", 'w') { |f| f.write(content) }
  end

  def wait_for_pscan_to_complete
    status = RestClient::get 'http://localhost:8085/JSON/pscan/view/recordsToScan/?zapapiformat=JSON'
    records_remaining = JSON.parse(status)['recordsToScan']
    until records_remaining != 0
      puts "waiting for passive scan to complete..! still #{records_remaining} to go"
    end

  end

end
