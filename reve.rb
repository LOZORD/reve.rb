require 'json'
require 'optparse'
require 'net/http'
require 'json'
require_relative 'secrets'

FAVORITES_FILE = 'favorites.txt'

options = {}

OptionParser.new do |opts|
  opts.banner = 'Usage: ruby reve.rb [options]'

  opts.on('-p', '--play [EPISODE]', 'Play radio', ' starting at EPISODE number') do |e_num|
    options[:play] = true
    options[:episode_number] = e_num.to_i
  end

  opts.on('-i', '--increasing', 'Play episodes in order of low to high') do
    options[:is_increasing] = true
  end

  opts.on('-d', '--decreasing', 'Play episodes in order of high to low') do
    options[:is_increasing] = false
  end

  opts.on('-a', '--add-favorite EPISODE', 'Add EPISODE number to favorites list') do |e_num|
    options[:add_favorite] = e_num.to_i
  end

  opts.on('-r', '--remove-favorite EPISODE', 'Remove EPISODE number from favorites list') do |e_num|
    options[:remove_favorite] = e_num.to_i
  end

  opts.on('-s', '--shuffle', 'Shuffle the play order') do
    options[:shuffle] = true
  end

  opts.on('-f', '--favorites-only', 'Only play episodes in the favorites list') do
    options[:favorites_only] = true
  end
end.parse!

MAIN_URL =
  "https://api.tumblr.com/v2/blog/reverberationradio.com/posts/audio?api_key=#{API_KEY}"
BASE_AUDIO_URL = 'http://traffic.libsyn.com/reverberationradio/Reverberation_'

def episode_to_url(episode_num)
  BASE_AUDIO_URL + episode_num.to_s + '.mp3'
end

# TODO: store latest episode number in a favorites _JSON_
# if the file hasn't been touched in at least a week, use the API
def fetch_num_episodes
  latest_post_url = MAIN_URL + "&limit=1"

  lpURI = URI(latest_post_url)
  resp = Net::HTTP.get(lpURI)
  payload = JSON.parse resp, symbolize_names: true

  latest_post = payload[:response][:posts].first

  latest_post[:slug].sub('reverberation', '').to_i
end

def num_episodes
  @num_episodes ||= fetch_num_episodes
end

def fetch_favorites
  favorites = []

  File.open(FAVORITES_FILE, 'r') do |file|
    file.each_line do |line|
      favorites << line.to_i
    end
  end

  favorites
end

def favorites
  @favorites ||= fetch_favorites
end

def update_favorites(options)
  my_favorites = favorites

  File.open(FAVORITES_FILE, 'r') do |file|
    file.each_line do |line|
      my_favorites << line.chomp.to_i
    end
  end

  my_favorites.uniq!

  if options.has_key? :remove_favorite
    my_favorites.reject { |favorite| favorite == options[:remove_favorite] }
  elsif options.has_key? :add_favorite
    my_favorites << options[:add_favorite]
  else
    puts 'Favorites was not modified'
    return
  end

  File.open(FAVORITES_FILE, 'w') do |file|
    file.puts my_favorites.map(&:to_s).join("\n")
  end
end

def play(options)
  episodes_to_play = (1..num_episodes).to_a

  if options.has_key? :favorites_only
    episodes_to_play &= favorites
  end

  if options.has_key? :is_increasing
    if options[:is_increasing]
      # do nothing
    else
      episodes_to_play.reverse!
    end
  elsif options.has_key? :shuffle
    episodes_to_play.shuffle!
  else
    # do nothing
  end

  episodes_to_play.each do |e_num|
    `ffplay #{ episode_to_url(e_num) }`
  end
end

def main(options)
  `touch #{ FAVORITES_FILE }`

  if options.has_key? :play
    play(options)
  else
    update_favorites(options)
  end
end

main(options)
