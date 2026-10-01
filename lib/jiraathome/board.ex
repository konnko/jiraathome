defmodule Jiraathome.Board do
  use Ash.Domain, otp_app: :jiraathome, extensions: [AshPhoenix]

  resources do
    resource Jiraathome.Board.Card do
      define :list_cards, action: :list_in_board_order
      define :list_column_cards, action: :list_column, args: [:status]
      define :get_card, action: :read, get_by: [:id]
      define :add_card, action: :add, args: [:status, :author_name]
      define :edit_card, action: :edit
      define :move_card, action: :move, args: [:status, :index]
      define :delete_card, action: :destroy
    end

    resource Jiraathome.Board.Comment do
      define :list_comments, action: :list_for_card, args: [:card_id]
      define :add_comment, action: :add, args: [:card_id, :author_name]
    end
  end

  forms do
    form :add_card, args: [:status, :author_name]
    form :add_comment, args: [:card_id, :author_name]
  end

  def columns do
    [backlog: "Бэклог", researching: "Исследуется", doing: "Делается", done: "Готово"]
  end

  def subscribe, do: Phoenix.PubSub.subscribe(Jiraathome.PubSub, "board")
end
