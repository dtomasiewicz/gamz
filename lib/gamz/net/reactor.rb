module Gamz
  module Net

    module Reactor

      def react(client, action, *data)
        if respond_to?(m = :"react_#{action}", true)
          return send m, client, *data
        else
          return :invalid_action
        end
      end

    end

  end
end