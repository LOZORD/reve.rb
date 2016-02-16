# require 'ffmpeg'
require 'net/http'
require 'json'
require_relative 'secrets'

url = "https://api.tumblr.com/v2/blog/reverberationradio.com/posts/audio?api_key=#{API_KEY}"

uri = URI(url)

episode_number = ARGV.first
search_slug = 'reverberation' + episode_number

episode_stream_url = nil

# puts search_slug

resp = Net::HTTP.get(uri)
payload = JSON.parse resp, symbolize_names: true
if payload[:meta][:msg] == 'OK'
  posts = payload[:response][:posts]
  episode = posts.find do |post|
    # puts post[:slug]
    # TODO: episode number might not be in range
    post[:slug] == search_slug
  end

  episode_stream_url = episode[:audio_source_url] || nil
  puts episode_stream_url
else
  puts 'ERROR'
end

if episode_stream_url
  `ffplay #{ episode_stream_url }`
end
