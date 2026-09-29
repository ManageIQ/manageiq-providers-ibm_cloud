require 'prism'
require 'bundler'

RSpec.describe 'container event catcher worker inline gems' do
  let(:worker_file_path)  { File.expand_path('../../../workers/container_event_catcher/worker', __dir__) }
  let(:gemfile_lock_path) { File.expand_path('../../../Gemfile.lock', __dir__) }

  def parse_inline_gemfile(file_path)
    result = Prism.parse_file(file_path.to_s)
    ast    = result.value

    gems = {:required => {}, :conditional => {}}
    find_gemfile_block(ast, gems)
    gems
  end

  def find_gemfile_block(node, gems, in_conditional: false, condition: nil)
    return unless node.kind_of?(Prism::Node)

    if node.kind_of?(Prism::CallNode) && node.name == :gem
      gem_name    = nil
      gem_version = nil

      if node.arguments && !node.arguments.arguments.empty?
        first_arg = node.arguments.arguments[0]
        gem_name  = first_arg.unescaped if first_arg.kind_of?(Prism::StringNode)

        if node.arguments.arguments.length > 1
          second_arg  = node.arguments.arguments[1]
          gem_version = second_arg.unescaped if second_arg.kind_of?(Prism::StringNode)
        end
      end

      if gem_name
        if in_conditional
          gems[:conditional][gem_name] = {:version => gem_version, :condition => condition}
        else
          gems[:required][gem_name] = gem_version
        end
      end
      return
    end

    # Handle both `if ENV.fetch('VAR')` and `if ENV['VAR']` conditionals
    if node.kind_of?(Prism::IfNode)
      predicate = node.predicate

      env_var = extract_env_var(predicate)

      if env_var
        find_gemfile_block(node.statements, gems, :in_conditional => true, :condition => env_var) if node.statements
        return
      end
    end

    node.compact_child_nodes.each do |child|
      find_gemfile_block(child, gems, :in_conditional => in_conditional, :condition => condition)
    end
  end

  # Returns the ENV variable name string for `ENV.fetch('VAR')` or `ENV['VAR']`,
  # or nil if the node is not one of those patterns.
  def extract_env_var(node)
    return nil unless node.kind_of?(Prism::CallNode)
    return nil unless node.receiver.kind_of?(Prism::ConstantReadNode) && node.receiver.name == :ENV
    return nil unless node.arguments && !node.arguments.arguments.empty?

    first_arg = node.arguments.arguments[0]
    return nil unless first_arg.kind_of?(Prism::StringNode)

    # ENV.fetch('VAR') => name :fetch  |  ENV['VAR'] => name :[]
    %i[fetch []].include?(node.name) ? first_arg.unescaped : nil
  end

  def parse_gemfile_lock(file_path)
    lockfile = Bundler::LockfileParser.new(File.read(file_path))
    gems     = lockfile.specs.to_h { |spec| [spec.name, spec.version.to_s] }
    raise "Could not find any gems in #{file_path}" if gems.empty?

    gems
  end

  it 'uses versions compatible with Gemfile.lock', :skip => !File.exist?(File.expand_path('../../../Gemfile.lock', __dir__)) do
    inline_gems    = parse_inline_gemfile(worker_file_path)
    installed_gems = parse_gemfile_lock(gemfile_lock_path)

    mismatches = []

    inline_gems[:required].each do |gem_name, requirement|
      next if requirement.nil?

      locked = installed_gems[gem_name]
      next unless locked

      mismatches << "#{gem_name}: required #{requirement}, locked #{locked}" unless Gem::Requirement.new(requirement).satisfied_by?(Gem::Version.new(locked))
    end

    inline_gems[:conditional].each do |gem_name, gem_info|
      requirement = gem_info[:version]
      next if requirement.nil?

      locked = installed_gems[gem_name]
      next unless locked # conditional gem not installed — skip

      mismatches << "#{gem_name} (conditional on #{gem_info[:condition]}): required #{requirement}, locked #{locked}" unless Gem::Requirement.new(requirement).satisfied_by?(Gem::Version.new(locked))
    end

    expect(mismatches).to be_empty, "Gem version mismatches:\n#{mismatches.map { |m| "  - #{m}" }.join("\n")}"
  end
end
