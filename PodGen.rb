$gen_pod_env = {}

$dev_folders = {}

$extra_config = {}

class ExtraConfig
  attr_accessor :name, :action

  def initialize(name, action)
    @name = name
    @action = action
  end

  def config(config)
    if name == config[:name]
      @action.call(config)
    end
  end
end

class PodDesc
  attr_accessor :name, :props

  def initialize(name, props)
    config = props
    extra_config = $extra_config[name]
    if !extra_config.nil?
      # puts extra_config
      extra_config.config(config)
    end
    @name = name; @props = config
  end

  def name() return @props[:name]; end
  def branch() return @props[:branch]; end
  def git() return @props[:git]; end
  def path() return @props[:path]; end
  def tag() return @props[:tag]; end
  def version() return @props[:version]; end
  def subspecs() return @props[:subspecs]; end

  # dev_属性
  def dev_folder() return @props[:dev_folder]; end

  # get code
  def get_pod_code()
    expr = "pod '#{name}'"
    if !path.nil?
      expr += ", :path => '#{path}'"
    elsif !dev_folder.nil? and !$dev_folders[dev_folder].nil?
      expr += ", :path => '../#{dev_folder}'"
    elsif !version.nil?
      expr += ", '#{version}'"
    elsif !tag.nil?
      expr += ", :git => '#{git}', :tag => '#{tag}'"
    elsif !branch.nil?
      expr += ", :git => '#{git}', :branch => '#{branch}'"
    end

    if !subspecs.nil?
      temp = subspecs
      subs = temp.split(",")

      subspecs_desc = ""
      subs.each do |sub|
        presub = sub.lstrip().rstrip()
        if presub.length() > 0
          subspecs_desc += "'#{presub}',"
        end
      end

      expr += ", :subspecs => [#{subspecs_desc}]"
    end

    # if !folder.blank?
    #   git_clone_at(git, folder, branch)
    # end
    puts expr
    return expr
  end

  # methos
  def deal_dev_folder()
    if !dev_folder.nil? and !$dev_folders[dev_folder].nil?
      ctx = $dev_folders[dev_folder]
      git = ctx[:git]
      branch = ctx[:branch]
      git_clone_at(git, "../#{dev_folder}", branch)
    end
  end

  def git_clone_at(git, folder, branch)
    if !Dir.exist?(folder)
      `git clone #{git} -b #{branch} #{folder}`
    end
  end

  # 开始生成pod
  def gen_pod()
    deal_dev_folder()
    return get_pod_code()
  end
end

def cover_config(name)
  $extra_config[name] = ExtraConfig.new(name, Proc.new { |x|
    yield x
  })
end

# 声明pods
def gen_pod(config)
  desc = PodDesc.new(config[:name], config)
  code = desc.gen_pod()
  eval(code)
end

# 配置文件声明开发文件夹
def dev_folder(name, git, branch = "master")
  $dev_folders[name] = { :git => git, :branch => branch }
end

# 声明配置文件地址
def pod_config(git, branch, force = false)
  path = "../_pod_config"
  if force
    `rm -rf #{path}`
  end
  if !Dir.exist?(path)
    `git clone #{git} -b #{branch} #{path}`
  end
  config_path = "../_pod_config/PodConfig.rb"
  if File.exist?(config_path)
    content = File.read(config_path)
    eval(content)
  end
end

# 全局变量
def gen_pod_env(props)
  $gen_pod_env = props
end
