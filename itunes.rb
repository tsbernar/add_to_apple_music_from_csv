require 'rubygems'
require 'curb'
require 'json'
require "net/http"
require 'net/https'

title = "Melancholy Mood"
artist = "Bob Dylan"


# look into multithreading this
def get_itunes_id(artist, title)
  url = 'https://itunes.apple.com/WebObjects/MZStore.woa/wa/search?clientApplication=MusicPlayer&term='

  c = Curl::Easy.new(url + title.gsub(' ', '%20')) do |curl| 
    curl.headers['X-Apple-Store-Front'] = '143446-10,32 ab:rSwnYxS0 t:music2'
    curl.headers['X-Apple-Tz'] = '7200'
  end

  c.perform

  data = JSON.parse(c.body_str)['storePlatformData']['lockup']['results']

  data.each do |data|
    track = data[1]

    if track['name'] and track['artistName'] and track['kind'] == 'song' \
      and track['name'].downcase == title.downcase and \
      track['artistName'].downcase == artist.downcase 
      puts track['name'] + " " + track['artistName']
      return track['id']  
    end
  end
  return nil
end

def add_song(itunes_identifier)
  add_url = 'https://ld-3.itunes.apple.com/WebObjects/MZDaap.woa/daap/databases/1/cloud-add'


  body = make_request_body(Time.new.to_i, itunes_identifier)

  headers = {
        "Proxy-Connection" => "keep-alive",
        "X-Apple-Store-Front" => "143441-1,32",
        "Client-iTunes-Sharing-Version" => "3.13",
        "Accept-Language" => "en-us, en;q=0.50",
        "Client-Cloud-DAAP-Version" => "1.2/iTunes-12.4.0.119",
        "Accept-Encoding" => "gzip",
        "X-Apple-itre" => "0",
        "Content-Length" => "77",
        "Client-DAAP-Version" => "3.13",
        "User-Agent" => "iTunes/12.4 (Macintosh; OS X 10.11.5) AppleWebKit/601.6.17",
        "Connection" => "keep-alive",
        "Content-Type" => "application/x-dmap-tagged",
        # Replace the values of the next three headers with the values you intercepted
        "X-Dsid" => "128787256",
        "X-Guid" => "ACBC3283CA19",
        "Cookie" => "amia-128787256=oZkDz+g/vJ2/Jk0ty+P1pmtWPu0QZLKRPVNfGQxWDMkOrDuIfh8Da8b8ew8ln4ga3CibKTo1nC8DsgwkL0VHqw==; amp=TrNz7Q1h9hK1ebYCMoOgy6GnXNQ3cbIOIJdMD2cmTlI1NhSdn/T6loQSlmoE9O0Psxe0uYdH49dXfwfd4wreOqVuH+pYMf1cEfPulbFX002oWY7NKq9ac0FcdusvAy0Ta3zGxgD/q0UC67KSB10VXQA2JfaO2CkDOgLrz2//a/CqkpUqxb/pAuVX9YqUKn8YSuHj7+gkDte0e3LkSpjjfO4ZfjFeHRK0/Cw5oqxNdX3/xEjTu+wMsuqaj+J4wQJk; groupingPillToken=1_iphone; mt-asn-128787256=5; mt-tkn-128787256=AuLgojfORnpXvDZrnWcPvt+Mgwe9CE/PDthCIoFI7A8uvcwPhmmlqWVSAuvr5+Mjxd8JHbcG+Ia4Qn2GInSugQ54LVC1E2n62FuNaT75j6bfSKvjO8vrJydF1dYtvSq41shxCfpLgeJiY7lZ8UFPVQZjD/IKoAWIJa4Sp4TEC889PeX01BYUMC1I+35rLVRUA0csVME=; mzf_in=122533; TrPod=3; X-Dsid=128787256; itscc=2%7C1464205064911%60721280109-721280109%600177; itspod=12; mz_at0-128787256=AwQAAAEBAAHWUAAAAABXRgIiNUyl7A+bCRE3PApin+BaVv4kEAE=; mz_at_ssl-128787256=AwUAAAEBAAHWUAAAAABXRgMc/lxu+YNzbvH/PUcFuVcmEJ1eQTw=; s_vi=[CS]v1|2B06DE7B050123A4-6000010400085A6E[CE]; xp_ci=3z2fvDJIz7Paz4kizBlYzdXqq1aCL"
  }

  body =  body.pack('C*')
  uri = URI.parse(add_url)

  proxy_addr = '127.0.0.1'
  proxy_port = 8888
   # Use this instead if using proxy to debug (Charles)
  http = Net::HTTP.new(uri.host, uri.port, proxy_addr, proxy_port)
  # http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  
  resp = http.request_post(uri.path, body, headers)
  puts resp.code
  puts resp.body


end


def make_request_body(timestamp, itunes_identifier)
    hex = '616a4341000000456d73746300000004559417a36d6c696400000004000000006d757372000000040000320a6d696b6400000001026d69646100000010616541690000000800000000118cd92c00'

    body = [hex].pack('H*').bytes
    timestamp = timestamp.to_s(16)
    timestamp = [timestamp].pack('H*').bytes
    body[16..19] = timestamp


    itunes_identifier = itunes_identifier.to_s(16)
    itunes_identifier = [itunes_identifier].pack('H*').bytes
    puts itunes_identifier
    body[body.length - 5.. body.length-1] = itunes_identifier

    return body

end


id = get_itunes_id(artist, title)
id = Integer(id)
puts id.class.name
add_song(id)

