require 'rancher_deployer/version'
require 'rancher_deployer/tag_checker'
require 'yaml'
require 'erb'
require 'logger'
require 'tty-command'
require 'rugged'
require 'netrc'

module RancherDeployer
  class Error < StandardError;
  end

  # When configuration file is not found or not set
  MissingConfig = Class.new(Error)

  class Deployer
    attr_reader :logger, :config, :current_branch

    def initialize
      @config         = {}
      @current_branch = ENV.fetch('INPUT_SOURCE_BRANCH')
      logger.debug %Q{Running plugin for branch "#{current_branch}"}
    end

    def load_config!
      config_file = validate_config!
      logger.info "Reading plugin configuration from file #{config_file}"
      # Parse configuration file also using ERB
      @config = YAML.load(ERB.new(File.read(config_file)).result)
    end

    def environments
      @__environments ||= begin
        load_config! if config.empty?
        config.select { |name, config| should_deploy?(name, config) }
      end
    end

    # Image name to use for new deployment
    def image_name(env_config, env_name)
      env_config.fetch('image') do
        logger.debug %Q{No image provided in config for #{env_name}, will build image name from env variables}
        image_prefix = config.fetch('image_prefix', 'drone')
        branch_slug  = ENV['INPUT_SOURCE_BRANCH'].to_s.gsub(/\/+/, '-')
        short_sha    = ENV['INPUT_COMMIT_SHA'].to_s[0, 8]
        repo         = ENV['INPUT_GIT_REPO'].to_s.downcase
        "#{repo}:#{image_prefix}-#{branch_slug}-#{short_sha}"
      end
    end

    def on_tag?
      !ENV['INPUT_GIT_TAG'].to_s.empty?
    end

    def deploy!
      # If no enviroments applicable ENVs will exit with status code 1
      logger.warn("No matching environments for #{current_branch}, deploy won't happen") and return if environments.empty?
      # Actual deploy
      logger.info "Will deploy to environment(s): #{environments.keys}"
      # Iterate through configurations and deploy services
      environments.each do |name, config|
        # Login command
        logger.info "Logging in to rancher at #{config['server_url']} and selecting first project"
        shell.run('rancher login', config['server_url'], '-t', "#{config['access_key']}:#{config['secret_key']}", (config['login_options'] if config['login_options']), in: echo_1, only_output_on_error: true)
        # Context switch
        logger.info "Switching context to #{config['project']}"
        shell.run('rancher', 'context', 'switch', config['project'])
        # Deploy services
        image_to_deploy = image_name(config, name)
        logger.info "Updating services: #{config['services']} with image '#{image_to_deploy}'"

        begin
            env_retries ||= 1

            config['services'].each do |service|
              logger.debug "Updating service #{service}"
              shell.run("rancher kubectl set image deployment #{service} #{service}=#{image_to_deploy}#{" #{config['kubectl_options']}" if config['kubectl_options']}", '-n', config['namespace'])
              logger.debug "Patch service spec #{service} with SHA #{ENV['INPUT_COMMIT_SHA']}"
              shell.run("rancher kubectl patch deployment #{service} #{" #{config['kubectl_options_patch']}" if config['kubectl_options_patch']}", '-n', config['namespace'])
            end
        rescue
            # Wait time in seconds
            wait_time = env_retries * 10
            logger.info "Update failed. Retry attempt #{env_retries}. Will sleep for #{wait_time} seconds."

            sleep(wait_time)

            # Retry for a couple of times
            retry if (env_retries += 1) <= 15
        end
      end
    end

    private

    # Predicate used to check if a configuration must be deployed
    def should_deploy?(name, config)
      # Skip dot names, used for templates
      return false if name.start_with?('.')
      # Check for tag deployments
      if on_tag?
        logger.debug "Running on git tag, checking tag flag #{config['only_tags']}"
        return config['only_tags'] === true
      end
      # Generic match based on regexp
      regexp = Regexp.new("^#{config['branch']}$")
      logger.debug "Matching branch regexp #{regexp} with current branch #{current_branch}: #{regexp.match?(current_branch)}"
      regexp.match?(current_branch) && config['only_tags'] != true
    end

    # Return a shell wrapper
    def shell
      @_cmd ||= TTY::Command.new(logger: logger)

    # Used as stdin for login command
    def echo_1
      StringIO.new.tap do |st|
        st.puts '1'
        st.rewind
      end
    end

    # Logger for output
    def logger
      @_logger ||= begin
        Logger.new($stdout).tap do |l|
          l.level = ENV.fetch('INPUT_LOGGING', 'info')
        end
      end
    end

    def validate_config!
      if ENV['INPUT_CONFIG_FILE'].to_s.empty?
        raise MissingConfig, %q{No configuration file set, please configure using ENV['INPUT_CONFIG_FILE']}
      end
      raise MissingConfig, "No configuration at #{ENV['INPUT_CONFIG_FILE']}" unless File.exists?(ENV['INPUT_CONFIG_FILE'])
      File.realpath(ENV['INPUT_CONFIG_FILE'])
    end
  end
end
