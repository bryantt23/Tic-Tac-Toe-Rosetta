require 'set'
 
module TicTacToe
#   looks like these are the winning positions
  LINES = [[1,2,3],[4,5,6],[7,8,9],[1,4,7],[2,5,8],[3,6,9],[1,5,9],[3,5,7]]
 
  class Game
#     initialize taking player 1 & 2 class as parameters
    def initialize(player_1_class, player_2_class)
      @board = Array.new(10) # we ignore index 0 for convenience
 
      @current_player_id = 0
#       makes first player x, second player 0
      @players = [player_1_class.new(self, "X"), player_2_class.new(self, "O")]

# displays that the current player goes first
      puts "#{current_player} goes first."
    end
#     http://stackoverflow.com/questions/5046831/why-use-rubys-attr-accessor-attr-reader-and-attr-writer
#   can only read the board & current player id, instance variable
    attr_reader :board, :current_player_id
 
#  play method
    def play
      loop do
#         current player gets the player marker
        place_player_marker(current_player)
 
#  show that the current player has won and print board
        if player_has_won?(current_player)
          puts "#{current_player} wins!"
          print_board
          return
#           if no winner & board is full, display it is a draw & print board 
        elsif board_full?
          puts "It's a draw."
          print_board
          return
        end
 
#  switch players
        switch_players!
      end
    end
 
#  free positions method
    def free_positions
#       1 through 9 inclusive are available
# select it if it is available?
      Set.new((1..9).select {|position| @board[position].nil?})
    end
 
#  place marker
#the position is where the player has selected
    def place_player_marker(player)
      position = player.select_position!
      
#       display which player & which position has been selected
      puts "#{player} selects #{player.marker} position #{position}"
      
#       mark the board position by the player
      @board[position] = player.marker
    end
 
#  if the player has any of the winning positions aka lines
# if any of the lines has been marked by the player
    def player_has_won?(player)
      LINES.any? do |line|
        line.all? {|position| @board[position] == player.marker}
      end
    end
 
#  full board if 
    def board_full?
#       http://stackoverflow.com/questions/885414/a-concise-explanation-of-nil-v-empty-v-blank-in-ruby-on-rails
# if free positions has no elements
      free_positions.empty?
    end
 
#  one player gets id 0, other id 1
    def other_player_id
      1 - @current_player_id
    end
 
#  current player becomes other player
    def switch_players!
      @current_player_id = other_player_id
    end
 
    def current_player
      @players[current_player_id]
    end
 
    def opponent
      @players[other_player_id]
    end
 
    def turn_num
      10 - free_positions.size
    end
 
    def print_board
      col_separator, row_separator = " | ", "--+---+--"
      label_for_position = lambda{|position| @board[position] ? @board[position] : position}
 
      row_for_display = lambda{|row| row.map(&label_for_position).join(col_separator)}
      row_positions = [[1,2,3], [4,5,6], [7,8,9]]
      rows_for_display = row_positions.map(&row_for_display)
      puts rows_for_display.join("\n" + row_separator + "\n")
    end
  end
 
  class Player
    def initialize(game, marker)
      @game = game
      @marker = marker
    end
    attr_reader :marker
  end
 
  class HumanPlayer < Player
    def select_position!
      @game.print_board
      loop do
        print "Select your #{marker} position: "
        selection = gets.to_i
        return selection if @game.free_positions.include?(selection)
        puts "Position #{selection} is not available. Try again."
      end
    end
 
    def to_s
      "Human"
    end
  end
 
  class ComputerPlayer < Player
    DEBUG = false # edit this line if necessary
 
    def group_positions_by_markers(line)
      markers = line.group_by {|position| @game.board[position]}
      markers.default = []
      markers
    end
 
    def select_position!
      opponent_marker = @game.opponent.marker
 
      winning_or_blocking_position = look_for_winning_or_blocking_position(opponent_marker)
      return winning_or_blocking_position if winning_or_blocking_position
 
      if corner_trap_defense_needed?
        return corner_trap_defense_position(opponent_marker)
      end
 
      # could make this smarter by sometimes doing corner trap offense
 
      return random_prioritized_position
    end
 
    def look_for_winning_or_blocking_position(opponent_marker)
      for line in LINES
        markers = group_positions_by_markers(line)
        next if markers[nil].length != 1
        if markers[self.marker].length == 2
          log_debug "winning on line #{line.join}"
          return markers[nil].first
        elsif markers[opponent_marker].length == 2
          log_debug "could block on line #{line.join}"
          blocking_position = markers[nil].first
        end
      end
      if blocking_position
        log_debug "blocking at #{blocking_position}"
        return blocking_position
      end
    end
 
    def corner_trap_defense_needed?
      corner_positions = [1, 3, 7, 9]
      opponent_chose_a_corner = corner_positions.any?{|pos| @game.board[pos] != nil}
      return @game.turn_num == 2 && opponent_chose_a_corner
    end
 
    def corner_trap_defense_position(opponent_marker)
      # if you respond in the center or the opposite corner, the opponent can force you to lose
      log_debug "defending against corner start by playing adjacent"
      # playing in an adjacent corner could also be safe, but would require more logic later on
      opponent_position = @game.board.find_index {|marker| marker == opponent_marker}
      safe_responses = {1=>[2,4], 3=>[2,6], 7=>[4,8], 9=>[6,8]}
      return safe_responses[opponent_position].sample
    end
 
    def random_prioritized_position
      log_debug "picking random position, favoring center and then corners"
      ([5] + [1,3,7,9].shuffle + [2,4,6,8].shuffle).find do |pos|
        @game.free_positions.include?(pos)
      end
    end
 
    def log_debug(message)
      puts "#{self}: #{message}" if DEBUG
    end
 
    def to_s
      "Computer#{@game.current_player_id}"
    end
  end
end
 
include TicTacToe
 
Game.new(ComputerPlayer, ComputerPlayer).play
puts
players_with_human = [HumanPlayer, ComputerPlayer].shuffle
Game.new(*players_with_human).play