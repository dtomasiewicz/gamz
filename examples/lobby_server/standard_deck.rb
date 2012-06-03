module StandardDeck

  def self.new
    ranks = (2..10).to_a + %w(A J Q K)
    suits = %w(S H C D)
    ranks.inject [] do |cards, rank|
      suits.map {|suit| cards << Card.new(rank, suit)}
      cards
    end
  end

  class Card

    attr_reader :rank, :suit

    def initialize(rank, suit)
      @rank, @suit, = rank, suit
    end

    def self.ordinal_rank(rank)
      if rank.kind_of?(Integer)
        if rank > 1 && rank < 11
          rank
        else
          raise "Invalid rank: #{rank}"
        end
      else
        {'A' => 1, 'J' => 11, 'Q' => 12, 'K' => 13}[rank] || raise("Invalid rank: #{rank}")
      end
    end

    def ordinal_rank
      self.class.ordinal_rank self
    end

    def to_s
      "#{rank}#{suit}"
    end

  end

end