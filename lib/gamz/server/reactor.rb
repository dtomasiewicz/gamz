module Gamz
  module Server

    module Reactor

      def on_action(client, action, *data)
        if respond_to?(m = :"react_#{action}", true)
          client = map_client client if respond_to? :map_client
          return send m, client, *data
        else
          return :invalid_action
        end
      end

    end

  end
end