class Assets::Watch < LuckyTask::Task
  summary "assets watch"

  # Watch::Assets
  # 1. load_manifest = public/manifest.json
  # 1. get all keys (relative file paths)
  # 1. watch for changes on each key
  # 1. if file changes: compute new md5 checksum and re-copy to public/assets, update public/manifest.json to new checksum value

  def call
    # Execute your task here
  end
end
