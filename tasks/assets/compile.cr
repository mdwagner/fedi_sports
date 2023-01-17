require "digest/md5"
require "file_utils"

class Assets::Compile < LuckyTask::Task
  summary "compile assets"

  # Compile::Assets
  # 1. get **/*.(js|css|etc.) files
  # 1. compute md5 checksums for each file
  # 1. copy each file to public/assets
  # 1. create public/manifest.json of "relative file path" => "server file path"

  switch :recompile, "Remove old assets first and then compile assets", shortcut: "-r"
  # 1. read public/manifest.json
  # 1. get file paths to all *values of manifest.json
  # 1. rm -rf file paths

  def call
    public_dir = Path.new("public")
    assets_dir = public_dir.join("assets")

    manifest_json_path = public_dir.join("manifest.json")

    if recompile?
      manifest_json = File.open(manifest_json_path) do |io|
        Hash(String, String).from_json(io)
      end

      manifest_json.values.each do |asset_path|
        realpath = public_dir.join(strip_components(Path.new(asset_path), 1))
        FileUtils.rm_rf(realpath)
      end
    end

    manifest = {} of String => String

    Dir.glob("src/**/*.js", "src/**/*.css") do |file|
      path = Path.new(file)
      content = File.read(file)
      md5 = Digest::MD5.hexdigest(content)
      key_path = strip_components(path, 1)

      case ext = path.extension
      when ".js", ".css"
        basename = File.basename(file, ext)
        new_file = assets_dir.join(key_path.dirname, "#{basename}.#{md5}#{ext}")
        FileUtils.mkdir_p(new_file.dirname)
        FileUtils.cp(file, new_file)
        manifest[key_path.to_s] = "/#{strip_components(new_file, 1)}"
      end
    end

    File.write(manifest_json_path, manifest.to_pretty_json)
  end

  private def strip_components(path : Path, strip)
    Path.new(path.parts[strip..])
  end
end
