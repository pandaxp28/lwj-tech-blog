#!/usr/bin/env ruby
# frozen_string_literal: true

module ZzzzzzzzDownloadLinkRewriter
  PLAIN_URL = 'www.lwj.co.jp/pc/software/index.html'
  INTERNAL_PATH = '/lwj-tech-blog/downloads/winmaintenancetool/'
  LINK_TEXT = 'WinMaintenanceTool ダウンロード案内ページ'

  def self.rewrite_html(text)
    cleaned = text.dup

    cleaned.gsub!(PLAIN_URL, %Q(<a href="#{INTERNAL_PATH}">#{LINK_TEXT}</a>))

    cleaned.gsub!(
      %Q(<code>http://www.lwj.co.jp/pc/software/index.html</code>),
      %Q(<a href="#{INTERNAL_PATH}">#{LINK_TEXT}</a>)
    )

    cleaned.gsub!(
      %Q(<code>https://github.com/pandaxp28/WinMaintenanceTool/releases</code>),
      %Q(<a href="https://github.com/pandaxp28/WinMaintenanceTool/releases">GitHub Releases</a>)
    )

    cleaned
  end
end

Jekyll::Hooks.register :site, :post_write do |site|
  Dir.glob(File.join(site.dest, '**', '*.html')).each do |path|
    next unless File.file?(path)
    original = File.read(path)
    cleaned = ZzzzzzzzDownloadLinkRewriter.rewrite_html(original)
    next if cleaned == original
    File.write(path, cleaned)
  end
end
