defmodule Jiraathome.Files do
  @moduledoc "Server-stored files, their lifecycle and weekly orphan cleanup."
  use Ash.Domain, otp_app: :jiraathome

  resources do
    resource Jiraathome.Files.Blob do
      define :get_file, action: :read, get_by: [:id]
      define :list_files, action: :read
      define :list_attachments, action: :by_ids, args: [:ids]
      define :store_file, action: :store, args: [:upload]
      define :register_file, action: :register
      define :mark_orphaned, action: :mark_orphaned
      define :mark_used, action: :mark_used
      define :delete_file, action: :hard_delete
      define :cleanup_unused_files, action: :cleanup
    end
  end
end
