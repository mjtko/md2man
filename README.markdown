# md2man - markdown to manpage

md2man is a Ruby library and command-line program that converts [Markdown]
documents into UNIX manual pages (both [roff] and HTML) using [Redcarpet].

## Features

  * Formats tagged and indented paragraphs (see "document format" below).

  * Translates all HTML4 and XHTML1 entities into native [roff] equivalents.

  * Supports markdown extensions such as [PHP Markdown Extra tables][tables].

  * Usable from the command line as a filter in a UNIX pipeline.

### Demonstration

Try converting [this example Markdown file][example] into a UNIX manual page:

    md2man EXAMPLE.markdown > EXAMPLE.1
    man -l EXAMPLE.1

![Obligatory screenshot of md2man(1) in action!](
https://raw.github.com/sunaku/md2man/master/EXAMPLE.png)

### Limitations

At present, md2man does not translate the following [Redcarpet] node types:

  * `block_html`
  * `strikethrough`
  * `superscript`
  * `image`
  * `raw_html`

It issues a warning when it encounters these instead.  Patches are welcome!

## Installation

    gem install md2man

### Development

    git clone git://github.com/sunaku/md2man
    cd md2man
    bundle install
    bundle exec md2man --help  # run it directly
    bundle exec rake --tasks   # packaging tasks

## Usage

### Document format

md2man extends [Markdown] syntax in the following ways, as provisioned in the
`Md2Man::Document` module and defined in its derivative `Md2Man::Roff` module:

  * Paragraphs whose lines are all uniformly indented by two spaces are
    considered to be "indented paragraphs".  They are unindented accordingly
    before emission as `.IP` in the [roff] output.

  * Paragraphs whose subsequent lines (all except the first) are uniformly
    indented by two spaces are considered to be a "tagged paragraphs".  They
    are unindented accordingly before emission as `.TP` in the [roff] output.

md2man extends [Markdown] semantics in the following ways:

  * The first top-level heading (H1) found in the document is emitted as `.TH`
    in the roff(7) output to define the UNIX manual page's header and footer.
    Any subsequent top-level headings (H1) are treated as second-level (H2).

### For [roff] output

#### At the command line

    md2man --help

#### Inside a Ruby script

Use the default renderer:

    require 'md2man'

    your_roff_output = Md2Man::ENGINE.render(your_markdown_input)

Build your own renderer:

    require 'md2man'

    engine = Redcarpet::Markdown.new(Md2Man::Engine, your_options_hash)
    your_roff_output = engine.render(your_markdown_input)

Define your own renderer:

    require 'md2man'

    class YourManpageRenderer < Md2Man::Engine
      # ... your stuff here ...
    end

    engine = Redcarpet::Markdown.new(YourManpageRenderer, your_options_hash)
    your_roff_output = engine.render(your_markdown_input)

Mix-in your own renderer:

    require 'md2man'

    class YourManpageRenderer < Redcarpet::Render::Base
      include Md2Man::Roff
      # ... your stuff here ...
    end

    engine = Redcarpet::Markdown.new(YourManpageRenderer, your_options_hash)
    your_roff_output = engine.render(your_markdown_input)

### For HTML output

#### At the command line

    md2man-html --help

#### Inside a Ruby script

Use the default renderer:

    require 'md2man/html/engine'

    your_html_output = Md2Man::HTML::ENGINE.render(your_markdown_input)

Build your own renderer:

    require 'md2man/html/engine'

    engine = Redcarpet::Markdown.new(Md2Man::HTML::Engine, your_options_hash)
    your_html_output = engine.render(your_markdown_input)

Define your own renderer:

    require 'md2man/html/engine'

    class YourManpageRenderer < Md2Man::HTML::Engine
      # ... your stuff here ...
    end

    engine = Redcarpet::Markdown.new(YourManpageRenderer, your_options_hash)
    your_html_output = engine.render(your_markdown_input)

Mix-in your own renderer:

    require 'md2man/html'

    class YourManpageRenderer < Redcarpet::Render::Base
      include Md2Man::HTML
      # ... your stuff here ...
    end

    engine = Redcarpet::Markdown.new(YourManpageRenderer, your_options_hash)
    your_html_output = engine.render(your_markdown_input)

### Building man pages

#### At the command line

    md2man-rake --help

#### Inside a Ruby script

Add this snippet to your gemspec file:

    s.files += Dir['man/man?/*.?']            # UNIX man pages
    s.files += Dir['man/**/*.{html,css,js}']  # HTML man pages
    s.add_development_dependency 'md2man', '~> 1.4'

Add this line to your Rakefile:

    require 'md2man/rakefile'

You now have a `rake md2man` task that builds manual pages from Markdown files
(with ".markdown", ".mkd", or ".md" extension) inside `man/man*/` directories.
There are also sub-tasks to build manual pages individually as [roff] or HTML.

If you're using Bundler, this task also hooks into Bundler's gem packaging
tasks and ensures that your manual pages are built for packaging into a gem:

    bundle exec rake build
    gem spec pkg/*.gem | fgrep man/

## License

Released under the ISC license.  See the LICENSE file for details.

[roff]: http://troff.org
[Markdown]: http://daringfireball.net/projects/markdown/
[Redcarpet]: https://github.com/vmg/redcarpet
[example]: https://raw.github.com/sunaku/md2man/master/EXAMPLE.markdown
[tables]: http://michelf.com/projects/php-markdown/extra/#table
