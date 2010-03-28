require 'ruby-debug'

class CommentsGenerator < Rails::Generator::NamedBase

  def initialize(runtime_args, runtime_options = {})
    super

    if runtime_args[0] == 'migration'
      options[:migration] = true
    elsif runtime_args[0] != 'go' || !options[:file]
      usage
    end

  end

  def manifest

    record do |m|
      m.directory "app/views/"
      if options[:migration]
        m.migration_template 'comments_migration.rb', 'db/migrate', :migration_file_name => "comments_migration"
      else
        m.file "../../../views/#{options[:file]}", "app/views/#{options[:file]}"
      end
    end
  end

  def add_options!(opt)
    opt.on("--c", "Generate comments layout partial") { |v| options[:file] = "_comments.haml"; }
    opt.on("--cs", "Generate single comment partial") { |v| options[:file] = "_comment.haml"; }
    opt.on("--ca", "Generate comment_add_form") { |v| options[:file] = "_comment_add_form.haml"; }
  end
end
