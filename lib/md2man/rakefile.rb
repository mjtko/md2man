require 'rake'

# build man pages before building ruby gem using bundler
if defined? Bundler::GemHelper
  %w[build install release].each {|t| task t => :md2man }
end

#-----------------------------------------------------------------------------
desc 'Build manual pages from Markdown files in man/.'
task :md2man => ['md2man:man', 'md2man:web']
#-----------------------------------------------------------------------------

mkds = FileList['man/**/*.{markdown,mkd,md}']
mans = mkds.pathmap('%X')
webs = mans.pathmap('%p.html')

render_file_task = lambda do |src, dst, renderer|
  directory dir = dst.pathmap('%d')
  file dst => [dir, src] do
    input = File.read(src)
    output = renderer.call(input)
    File.open(dst, 'w') {|f| f << output }
  end
end

#-----------------------------------------------------------------------------
desc 'Build UNIX manual pages from Markdown files in man/.'
task 'md2man:man' => mans
#-----------------------------------------------------------------------------

mkds.zip(mans).each do |src, dst|
  render_file_task.call src, dst, lambda {|input|
    require 'md2man/engine'
    Md2Man::ENGINE.render(input)
  }
end

#-----------------------------------------------------------------------------
desc 'Build HTML manual pages from Markdown files in man/.'
task 'md2man:web' => ['man/index.html', 'man/style.css']
#-----------------------------------------------------------------------------

wrap_html_template = lambda do |title, content, ascent|
<<WRAP_HTML_TEMPLATE
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="generator" content="md2man #{Md2Man::VERSION} https://github.com/sunaku/md2man" />
  <title>#{title}</title>
  <link rel="stylesheet" href="#{ascent}style.css"/>
  <!--[if lt IE 9]><script src="http://html5shiv.googlecode.com/svn/trunk/html5.js"></script><![endif]-->
</head>
<body>#{content}</body>
</html>
WRAP_HTML_TEMPLATE
end

parse_manpage_name = lambda do |html_file_name|
  html_file_name.pathmap('%n').sub(/\.(.+)$/, '(\1)')
end

parse_manpage_info = lambda do |html_file_body|
  if html_file_body =~ %r{<p>.+?\s-\s+(.+?)</p>}
    $1.gsub(/<.+?>/, '') # strip HTML tags
  end
end

file 'man/index.html' => webs do |t|
  buffer = ['<div class="container-fluid">']
  webs.sort.group_by {|web| web.pathmap('%d').sub('man/', '') }.each do |subdir, dir_webs|
    buffer << %{<h2 id="#{subdir}">#{subdir}</h2>}
    dir_webs.each do |web|
      name = parse_manpage_name.call(web)
      info = parse_manpage_info.call(File.read(web))
      link = %{<a href="#{web.sub('man/', '')}">#{name}</a>}
      buffer << %{<dl class="dl-horizontal"><dt>#{link}</dt><dd>#{info}</dd></dl>}
    end
  end
  buffer << '</div>'
  content = buffer.join

  title = t.name.pathmap('%X')
  output = wrap_html_template.call(title, content, nil)
  File.open(t.name, 'w') {|f| f << output }
end

file 'man/style.css' => __FILE__.pathmap('%X/style.css') do |t|
  cp t.prerequisites.first, t.name if t.needed?
end

mkds.zip(webs).each do |src, dst|
  render_file_task.call src, dst, lambda {|input|
    require 'md2man/html/engine'
    output = Md2Man::HTML::ENGINE.render(input).
      # deactivate external manual page cross-references
      gsub(/(?<=<a class="manpage-reference") href="\.\.(.+?)"/) do
        $& if webs.include? 'man' + $1
      end

    name = parse_manpage_name.call(dst)
    info = parse_manpage_info.call(output)
    title = [name, info].compact.join(' &mdash; ')

    subdir = dst.pathmap('%d').sub('man/', '')
    ascent = '../' * (dst.count('/') - 1)
    content = [
      '<div class="navbar">',
        '<div class="navbar-inner">',
          '<span class="brand">',
            %{<a href="#{ascent}index.html##{subdir}">#{subdir}</a>},
            '/',
            dst.pathmap('%n'),
          '</span>',
        '</div>',
      '</div>',
      '<div class="container-fluid">',
        '<div class="manpage">',
          output,
        '</div>',
      '</div>',
    ].join

    wrap_html_template.call title, content, ascent
  }
end
