namespace :release do
  desc "Release a new project version"
  task :release do
    require 'pathname'

    version = ENV["RELEASE_VERSION"]
    if version.nil? || version.empty?
      warn "ERROR: You must set the env var RELEASE_VERSION to the proper value."
      exit 1
    end

    branch = `git rev-parse --abbrev-ref HEAD`.chomp
    if branch == "master"
      warn "ERROR: You cannot cut a release from the master branch."
      exit 1
    end

    root = Pathname.new(__dir__).join("../..")

    # Update workers/container_event_catcher/worker branch to tag
    worker_file = root.join("workers", "container_event_catcher", "worker")
    worker_content = worker_file.read if worker_file.exist?

    files_to_update = []
    if worker_file.exist?
      new_content = worker_content.gsub(/:branch\s*=>\s*(['"])#{Regexp.escape(branch)}\1/, ":tag => \\1#{version}\\1")
      if new_content != worker_content
        worker_file.write(new_content)
        files_to_update << worker_file
      end
    end

    # Commit
    exit $?.exitstatus unless system("git add #{files_to_update.join(' ')}")
    exit $?.exitstatus unless system("git commit -m 'Release #{version}'")

    # Tag
    exit $?.exitstatus unless system("git tag #{version} -m 'Release #{version}'")

    # Revert the worker update
    worker_file.write(worker_content) if worker_file.exist?

    # Commit
    exit $?.exitstatus unless system("git add #{files_to_update.join(' ')}")
    exit $?.exitstatus unless system("git commit -m 'Revert worker tag reference update and put back branch reference'")

    puts
    puts "The commit on #{branch} with the tag #{version} has been created."
    puts "Run the following to push to the upstream remote:"
    puts
    puts "\tgit push upstream #{branch} #{version}"
    puts
  end

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
