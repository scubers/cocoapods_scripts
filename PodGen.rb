$gen_pod_intercepter = {}

def config_pod(props)
  $gen_pod_intercepter[props[:name]] = props[:branch]
end

def get_config_branch(name)
  return $gen_pod_intercepter[name]
end

def gen_pod(config)
  branch = config[:branch]
  git = config[:git]
  path = config[:path]
  tag = config[:tag]
  version = config[:version]
  name = config[:name]
  specs = config[:subspecs]

  cover_branch = get_config_branch(name)
  if !cover_branch.blank?
    # 覆盖branch
    puts "cover_branch<#{name}>: #{cover_branch}"
    branch = cover_branch
  end

  expr = "pod '#{name}'"

  if !path.blank?
    expr += ", :path => '#{path}'"
  elsif !version.blank?
    expr += ", '#{version}'"
  elsif !tag.blank?
    expr += ", :git => '#{git}', :tag => '#{tag}'"
  elsif !branch.blank?
    expr += ", :git => '#{git}', :branch => '#{branch}'"
  end

  if !specs.blank?
    temp = specs
    subs = temp.split(",")

    subspecs = ""
    subs.each do |sub|
      presub = sub.lstrip().rstrip()
      if presub.length() > 0
        subspecs += "'#{presub}',"
      end
    end

    expr = expr + ", :subspecs => [#{subspecs}]"
  end
  puts expr
  eval(expr)
end

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
