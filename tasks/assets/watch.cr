require "./compile"

module LuckySentry
  class ProcessRunner
    include LuckyTask::TextHelpers

    getter build_processes = [] of Process
    getter app_processes = [] of Process
    getter! watcher : Watcher
    property successful_compilations
    property app_built
    property? reload_browser

    @app_built : Bool = false
    @successful_compilations : Int32 = 0

    def initialize(@build_commands : Array(String), @run_commands : Array(String), @files : Array(String), @reload_browser : Bool, @watcher : Watcher?)
    end

    private def build_app_processes_and_start
      @build_processes.clear
      @build_commands.each do |command|
        @build_processes << Process.new(command, shell: true, output: STDOUT, error: STDERR)
      end
      build_processes_copy = @build_processes.dup
      spawn do
        build_statuses = build_processes_copy.map(&.wait)
        success = build_statuses.all?(&.success?)
        if build_processes == build_processes_copy # if this build was not aborted in #stop_all_processes
          start_all_processes(success)
        end
      end
    end

    private def create_app_processes
      @app_processes.clear
      @run_commands.each do |command|
        @app_processes << Process.new(command, shell: false, output: STDOUT, error: STDERR)
      end

      @successful_compilations += 1
      if reload_browser?
        reload_or_start_watcher
      end
      if @successful_compilations == 1
        spawn do
          sleep(0.3)
          print_running_at
        end
      end
    end

    private def reload_or_start_watcher
      if @successful_compilations == 1
        start_watcher
      else
        reload_watcher
      end
    end

    private def start_watcher
      watcher.start unless watcher.running?
    end

    private def print_running_at
      STDOUT.puts ""
      STDOUT.puts running_at_background
      STDOUT.puts running_at_message.colorize.on_cyan.black
      STDOUT.puts running_at_background
      STDOUT.puts ""
    end

    private def running_at_background
      extra_space_for_emoji = 1
      (" " * (running_at_message.size + extra_space_for_emoji)).colorize.on_cyan
    end

    private def running_at_message
      "   🎉 App running at #{running_at}   "
    end

    private def running_at
      if reload_browser?
        watcher.running_at || original_url
      else
        original_url
      end
    end

    private def original_url
      "http://#{Lucky::ServerSettings.host}:#{Lucky::ServerSettings.port}"
    end

    private def reload_watcher
      watcher.reload
    end

    private def get_timestamp(file : String)
      File.info(file).modification_time.to_s("%Y%m%d%H%M%S")
    end

    def restart_app
      build_in_progress = @build_processes.any?(&.exists?)
      stop_all_processes
      puts build_in_progress ? "Recompiling..." : "\nCompiling..."
      build_app_processes_and_start
    end

    private def stop_all_processes
      @build_processes.each do |process|
        unless process.terminated?
          # kill child process, because we started build process with shell option
          Process.run("pkill -P #{process.pid}", shell: true)
          process.terminate
        end
      end
      @app_processes.each do |process|
        process.terminate unless process.terminated?
      end
    end

    private def start_all_processes(build_success : Bool)
      if build_success
        self.app_built = true
        create_app_processes
        puts "#{" Done ".colorize.on_cyan.black} compiling"
      elsif !app_built
        print_error_message
      end
    end

    private def print_error_message
      if successful_compilations.zero?
        puts <<-ERROR
        #{"---".colorize.dim}
        Feeling stuck? Try this...
          ▸  Run setup: #{"script/setup".colorize.bold}
          ▸  Reinstall shards: #{"rm -rf lib bin && shards install".colorize.bold}
          ▸  Ask for help: #{"https://luckyframework.org/chat".colorize.bold}
        ERROR
      end
    end

    def scan_my_files
      file_changed = false
      app_processes = @app_processes
      files = @files
      files_changed = [] of String
      Dir.glob(files) do |file|
        timestamp = get_timestamp(file)
        if FILE_TIMESTAMPS[file]? && FILE_TIMESTAMPS[file] != timestamp
          FILE_TIMESTAMPS[file] = timestamp
          file_changed = true
          files_changed << file
        elsif FILE_TIMESTAMPS[file]?.nil?
          FILE_TIMESTAMPS[file] = timestamp
          if (app_processes.none? &.terminated?)
            file_changed = true
            files_changed << file
          end
        end
      end

      if file_changed # (file_changed || app_processes.empty?)
        if files_changed.any? { |f| File.match?("**src/js/*.js", f) || File.match?("**src/css/*.css", f) }
          ::Assets::Compile.new.call
        end

        restart_app

        files_changed.clear
      end
    end
  end
end

class Assets::Watch < LuckyTask::Task
  summary "assets watch"

  # Watch::Assets
  # 1. load_manifest = public/manifest.json
  # 1. get all keys (relative file paths)
  # 1. watch for changes on each key
  # 1. if file changes: compute new md5 checksum and re-copy to public/assets, update public/manifest.json to new checksum value

  def call
    build_commands = %w(crystal build ./src/start_server.cr -o bin/start_server)
    files = ["./src/**/*.cr", "./src/**/*.ecr", "./config/**/*.cr", "./shard.lock"]
    files << "./src/**/*.js"
    files << "./src/**/*.css"

    build_commands << "-Dlivereloadws"
    watcher_class = LuckySentry::WebSocketWatcher.new

    #build_commands << "--error-trace"
    build_commands = [build_commands.join(" ")]
    run_commands = %w(./bin/start_server)

    process_runner = LuckySentry::ProcessRunner.new(
      files: files,
      build_commands: build_commands,
      run_commands: run_commands,
      reload_browser: true,
      watcher: watcher_class
    )

    puts "Beginning to watch your project"

    while true
      process_runner.scan_my_files
      sleep 0.1
    end
  end
end
