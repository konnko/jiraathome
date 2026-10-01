defmodule Jiraathome.Files do
  @moduledoc "Server-stored files, their lifecycle and weekly orphan cleanup."
  use Ash.Domain, otp_app: :jiraathome

  resources do
    resource Jiraathome.Files.Blob do
      define :get_file, action: :read, get_by: [:id]
      define :list_files, action: :read
      define :list_attachments, action: :list_by_ids, args: [:ids]
      define :store_upload, action: :store_upload, args: [:upload]
      define :register_stored_file, action: :register_stored
      define :mark_orphaned, action: :mark_orphaned
      define :mark_used, action: :mark_used
      define :delete_file, action: :delete_with_stored_contents
      define :clean_up_unreferenced_files, action: :clean_up_unreferenced
    end
  end
end
