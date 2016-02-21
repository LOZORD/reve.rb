# XXX: NOTE this file is not useful as all audio urls are similar besides the
# episode number. How lucky for me!
require 'net/http'
require 'json'
require_relative 'secrets'

MAIN_URL = 
  "https://api.tumblr.com/v2/blog/reverberationradio.com/posts/audio?api_key=#{API_KEY}"

MAIN_URI = URI(MAIN_URL)

cache_hash = {}

num_episodes = nil

first_resp = Net::HTTP.get(MAIN_URI)

first_payload = JSON.parse first_resp, symbolize_names: true

# puts first_payload

if first_payload[:meta][:msg] == 'OK'
  # posts = first_payload[:response][:posts]
  num_episodes = first_payload[:response][:total_posts]
end

puts num_episodes

episode_ctr = 0

payload = first_payload

# cache_size_changed = true
done_caching = false

until cache_hash.size == num_episodes || done_caching
  fail 'ERROR!' unless payload[:meta][:msg] == 'OK'
  posts = payload[:response][:posts]

  posts.each do |post|
    num = post[:slug].sub('reverberation', '').to_i
    url = post[:audio_source_url]

    if cache_hash.has_key? num
      done_caching = true
    else
      cache_hash[num] = url
    end
  end

  puts "#{cache_hash.size} / #{num_episodes} stored"

  # make another request
  offset_url = MAIN_URL + "&offset=#{cache_hash.size}"
  puts offset_url
  offset_uri = URI(offset_url)
  resp = Net::HTTP.get(offset_uri)
  payload = JSON.parse resp, symbolize_names: true
  # puts payload
end

puts 'Writing data/url-cache.json'

File.open('data/url-cache.json', 'w') do |file|
  file.write(cache_hash.to_json)
  puts 'File written'
end
