defmodule Jiraathome.Documents do
  use Ash.Domain, otp_app: :jiraathome

  resources do
    resource Jiraathome.SharedFile.Update do
      define :updates_after, action: :after_sequence, args: [:sequence]
      define :get_update_by_token, action: :read, get_by: [:token]
      define :append_update, action: :append
    end
  end
end
