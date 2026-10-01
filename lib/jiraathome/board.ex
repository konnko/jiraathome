defmodule Jiraathome.Board do
  use Ash.Domain, otp_app: :jiraathome

  resources do
    resource Jiraathome.Board.Card do
      define :list_cards, action: :list
      define :get_card, action: :read, get_by: [:id]
      define :create_card, action: :create, args: [:author_name]
      define :update_card, action: :update
      define :move_card, action: :move, args: [:status]
      define :delete_card, action: :destroy
    end

    resource Jiraathome.Board.Comment do
      define :list_comments, action: :for_card, args: [:card_id]
      define :create_comment, action: :create, args: [:card_id, :author_name]
    end
  end

  def columns do
    [backlog: "Бэклог", researching: "Исследуется", doing: "Делается", done: "Готово"]
  end

  def subscribe, do: Phoenix.PubSub.subscribe(Jiraathome.PubSub, "board")
end
