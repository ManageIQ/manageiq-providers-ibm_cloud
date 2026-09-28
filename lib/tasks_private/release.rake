namespace :release do
  desc "Tasks to run on a new branch when a new branch is created"
  task :new_branch do
    require 'pathname'

    branch = ENV["RELEASE_BRANCH"]
    if branch.nil? || branch.empty?
      warn "ERROR: You must set the env var RELEASE_BRANCH to the proper value."
      exit 1
    end

    current_branch = `git rev-parse --abbrev-ref HEAD`.chomp
    if current_branch == "master"
      warn "ERROR: You cannot do new branch tasks from the master branch."
      exit 1
    end

    root = Pathname.new(__dir__).join("../..")

    files_to_update = []

    # Update workers/container_event_catcher/worker branch
    worker_file = root.join("workers", "container_event_catcher", "worker")
    if worker_file.exist?
      content = worker_file.read
      new_content = content.gsub(/(:branch\s*=>\s*['"])[^'"]+(['"])/, "\\1#{branch}\\2")
      if new_content != content
        worker_file.write(new_content)
        files_to_update << worker_file
      end
    end

    if files_to_update.empty?
      puts "No files needed to be updated for branch #{branch}."
      exit 0
    end

    exit $?.exitstatus unless system("git add #{files_to_update.join(' ')}")
    exit $?.exitstatus unless system("git commit -m 'Changes for new branch #{branch}'")

    puts
    puts "The commit on #{current_branch} has been created."
    puts "Run the following to push to the upstream remote:"
    puts
    puts "\tgit push upstream #{current_branch}"
    puts
  end
end
