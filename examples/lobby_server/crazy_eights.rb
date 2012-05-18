#!/usr/bin/env ruby

require 'gamz/lobby'
require 'gamz/support'

class Player

  attr_accessor :name, :hand

  def initialize(name)
    @name = name
    @hand = []
  end

  def to_s
    @name
  end

end

class CrazyEights < Gamz::Lobby::Game

  MIN_PLAYERS = 2
  MAX_PLAYERS = 4
  HAND_SIZE = 8

  def setup
    @turn = 0
    @deck = Gamz::Support::StandardDeck.new
    @discard = []

    @deck.shuffle!

    inform_all :players, players

    # deal
    players.each do |player|
      HAND_SIZE.times do
        player.hand << @deck.pop
      end
      inform_others :hand_dealt, player, player.hand.size
      inform player, :hand, player.hand
    end
    up = @deck.pop
    @discard << up
    inform_all :up_card, up

    # if 8 is up, dealer may declare the initial suit
    if up.rank == 8
      @current_suit = nil
    else
      set_current_suit up.suit
      advance_turn
    end
  end

  def player_left(player)
    @pos = players.index player
    @dc_current = player == current_player

    super

    if players.length >= MIN_PLAYERS
      # resolve suit declaration (use suit of up-card)
      set_current_suit up_card.suit unless @current_suit

      # resolve turn (advance iff current player disconnected)
      @turn -= 1 if @pos < @turn
      @turn %= players.length
      inform_turn if @dc_current
    else
      inform_all :not_enough_players
      finished
    end
  end

  # The following actions may be performed only when it is a player's
  # turn.

  def do_declare_suit(player, suit)
    return :not_your_turn unless current_player == player
    return :invalid_action if @current_suit
    return :invalid_suit unless %w(S H C D).include?(suit)

    set_current_suit suit
    advance_turn

    return :success
  end

  def do_pass(player)
    return :not_your_turn unless current_player == player
    return :invalid_action unless @current_suit
    return :have_playable_card if has_playable_card?(player)

    inform_others :pass, player
    advance_turn

    return :success
  end

  def do_play_card(player, index)
    index = index.to_i
    return :not_your_turn unless current_player == player
    return :invalid_action unless @current_suit
    return :invalid_card unless card = player.hand[index]
    return :card_not_playable unless card_playable?(card)

    @discard << player.hand.delete_at(index)
    inform_others :card_played, player, card

    if card.rank == 8
      @current_suit = nil
    else
      if card.suit != @current_suit
        set_current_suit card.suit
      end
      advance_turn
    end

    return :success
  end

  def do_draw_card(player)
    return :not_your_turn unless current_player == player
    return :invalid_action unless @current_suit
    return :have_playable_card if has_playable_card?(player)
    return :deck_empty if @deck.empty?

    card = @deck.pop
    player.hand << card
    inform_others :card_drawn, player

    return :success, card
  end

  # BEGIN QUERY METHODS
  # These methods are not necessary, but they simplify playability with
  # simple clients that don't remember these things.

  def do_hand(player)
    return :success, player.hand
  end

  # END QUERY METHODS

  private

  def inform_turn
    inform current_player, :your_turn
    inform_others :turn, current_player
  end

  def up_card
    @discard.last
  end

  def advance_turn
    @turn = (@turn+1) % players.length
    inform_turn
  end

  def current_player
    players[@turn]
  end

  def set_current_suit(suit)
    @current_suit = suit
    inform_all :current_suit, suit
  end

  def has_playable_card?(player)
    player.hand.each do |card|
      return true if card_playable?(card)
    end
    false
  end

  def card_playable?(card)
    card.suit == @current_suit || card.rank == up_card.rank || card.rank == 8
  end

end

Gamz::Lobby.new(CrazyEights, Player).start (ARGV[0] || 10000).to_i, (ARGV[1] || 10001).to_i
