defmodule Jiraathome.Documents do
  @moduledoc "The shared document, stored as an append-only log of Yjs updates."
  use Ash.Domain, otp_app: :jiraathome

  resources do
    resource Jiraathome.Documents.SharedFileUpdate do
      define :list_updates_after, action: :list_after_sequence, args: [:sequence]
      define :get_update_by_token, action: :read, get_by: [:token]
      define :append_update, action: :append
    end
  end
end
