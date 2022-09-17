require_relative 'grid'
require_relative 'pieces'
require_relative 'referee'
require_relative 'misc'

STDOUT.sync = true

$game = Referee.new
$game.setup
$game.display

$game.start!

loop do 
  sleep 0.1
  $game.display
  break if $game.over?
end

puts
