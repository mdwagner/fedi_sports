class Assets::Compile < LuckyTask::Task
  summary "assets compile"

  # Compile::Assets
  # 1. get **/*.(js|css|etc.) files
  # 1. compute md5 checksums for each file
  # 1. copy each file to public/assets
  # 1. create public/manifest.json of "relative file path" => "server file path"

  def call
    # Execute your task here
  end
end
