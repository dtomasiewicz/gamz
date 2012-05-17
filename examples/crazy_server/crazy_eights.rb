#!/usr/bin/env ruby

require 'gamz'
require_relative 'lobby_server'

class Player

  attr_accessor :name, :hand

  def initialize(client, name)
    @name = name
    @hand = []
  end

  def to_s
    @name
  end

end

class CrazyEights < Gamz::Game

  MIN_PLAYERS = 2
  MAX_PLAYERS = 4
  HAND_SIZE = 8

  def start
    @turn = 0
    @deck = Gamz::Support::StandardDeck.new
    @dicard = []

    @deck.shuffle!

    # deal
    players.each do |player|
      HAND_SIZE.times do
        player.hand << @deck.pop
      end
      inform_except player, :hand_dealt, {player: player, size: player.hand.size}
      inform player, :hand_dealt, {hand: player.hand}
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

  # The following actions may be performed only when it is a player's
  # turn.

  def declare_suit(player, suit)
    raise rv :not_your_turn unless current_player == player
    raise rv :invalid_action if @current_suit
    raise rv :invalid_suit unless ['S', 'H', 'C', 'D'].include?(suit)

    set_current_suit suit
    advance_turn
  end

  def pass(player)
    raise rv :not_your_turn unless current_player == player
    raise rv :invalid_action unless @current_suit
    raise rv :have_playable_card if has_playable_card?(player)

    inform_all :pass, player
    advance_turn
  end

  def play_card(player, index)
    raise rv :not_your_turn unless current_player == player
    raise rv :invalid_action unless @current_suit
    raise rv :invalid_card unless player.hand[index]
    raise rv :card_not_playable unless card_playable?(card)

    card = @player.delete_at index
    @discard << card
    inform_all :card_played, player, card

    if card.rank == 8
      @current_suit = nil
    else
      if card.suit != @current_suit
        set_current_suit card.suit
      end
      advance_turn
    end
  end

  def draw_card(player)
    raise rv :not_your_turn unless current_player == player
    raise rv :invalid_action unless @current_suit
    raise rv :have_playable_card if has_playable_card?(player)
    raise rv :deck_empty if @deck.empty?

    card = @deck.pop
    @player.hand << card
    inform_except player, :card_drawn, {player: player}
    inform player, :card_drawn, {card: card}
  end

  private

  def up_card
    @discard.last
  end

  def advance_turn
    @turn = (@turn+1) % players.length
    inform_all :turn, current_player
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

LobbyServer.new(CrazyEights, Player).start (ARGV[0] || 10000).to_i, (ARGV[1] || 10001).to_i
