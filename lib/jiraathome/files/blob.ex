defmodule Jiraathome.Files.Blob do
  use Ash.Resource,
    otp_app: :jiraathome,
    domain: Jiraathome.Files,
    data_layer: AshSqlite.DataLayer

  alias Jiraathome.Files.Blob.{Actions, Changes, Validations}

  sqlite do
    table "media"
    repo Jiraathome.Repo

    custom_indexes do
      index [:orphaned_at]
    end
  end

  actions do
    defaults [:read]

    read :list_by_ids do
      argument :ids, {:array, :string}, allow_nil?: false
      filter expr(id in ^arg(:ids))
      prepare build(sort: [inserted_at: :asc])
    end

    action :store_upload, :struct do
      description "Копирует загрузку в хранилище и регистрирует её как пока ни к чему не привязанный файл."
      constraints instance_of: __MODULE__
      argument :upload, :struct, allow_nil?: false, constraints: [instance_of: Plug.Upload]
      validate Validations.UploadWithinSizeLimit
      run Actions.StoreUpload
    end

    create :register_stored do
      description "Запись о файле, который уже лежит в хранилище. Отсчёт срока хранения начинается сразу."
      accept [:id, :name, :content_type, :size]
      change set_attribute(:orphaned_at, &DateTime.utc_now/0)
    end

    update :mark_orphaned do
      change set_attribute(:orphaned_at, &DateTime.utc_now/0)
    end

    update :mark_used do
      change set_attribute(:orphaned_at, nil)
    end

    destroy :delete_with_stored_contents do
      change Changes.DeleteStoredContents
    end

    action :clean_up_unreferenced, :integer do
      description "Помечает неиспользуемые файлы и удаляет те, что не используются больше недели. Возвращает число удалённых."
      run Actions.CleanUpUnreferenced
    end
  end

  attributes do
    uuid_primary_key :id, writable?: true
    attribute :name, :string, allow_nil?: false, public?: true
    attribute :content_type, :string, allow_nil?: false, public?: true
    attribute :size, :integer, allow_nil?: false, public?: true, constraints: [min: 0]
    attribute :orphaned_at, :utc_datetime_usec
    create_timestamp :inserted_at, type: :utc_datetime
  end
end
