module RSpec::Puppet
  module ClassExampleGroup
    include RSpec::Puppet::Matchers
    include RSpec::Puppet::Support

    def subject
      @catalogue ||= catalogue
    end

    def catalogue
      Puppet[:modulepath] = self.respond_to?(:module_path) ? module_path : RSpec.configuration.module_path

      klass_name = self.class.top_level_description.downcase

      # If we're testing a standalone module (i.e. one that's outside of a
      # puppet tree), the autoloader won't work, so we need to fudge it a bit.
      if File.exists?(File.join(Puppet[:modulepath], 'manifests', 'init.pp'))
        path_to_manifest = File.join([Puppet[:modulepath], 'manifests', klass_name.split('::')[1..-1]].flatten)
        import_str = "import '#{Puppet[:modulepath]}/manifests/init.pp'\nimport '#{path_to_manifest}.pp'\n"
      else
        import_str = ""
      end

      if !self.respond_to?(:params) || params == {}
        Puppet[:code] = import_str + "include #{klass_name}"
      else
        Puppet[:code] = import_str + 'class' + " { " + klass_name + ": " + params.keys.map { |r| "#{r.to_s} => '#{params[r].to_s}'"
      }.join(', ') + " }"
      end

      nodename = self.respond_to?(:node) ? node : Puppet[:certname]
      facts_val = self.respond_to?(:facts) ? facts : {}
      additional_resources = self.respond_to?(:virtual_resources) ? virtual_resources : []

      build_catalog(nodename, facts_val, additional_resources)
    end
  end
end
