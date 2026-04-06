#!/usr/bin/env ruby
# frozen_string_literal: true

module ZzzzHttpLinkSanitizer
  TARGET_URL = 'http://www.lwj.co.jp/pc/software/index.html'
  PLAIN_TEXT = 'LWJ ソフトウェア紹介ページ（www.lwj.co.jp/pc/software/index.html）'

  def self.sanitize_source(text)
    cleaned = text.dup
    cleaned.gsub!("[LWJ ソフトウェア紹介ページ](#{TARGET_URL})", PLAIN_TEXT)
    cleaned.gsub!(TARGET_URL, 'www.lwj.co.jp/pc/software/index.html')
    cleaned
  end

  def self.sanitize_html(text)
    cleaned = text.dup
    cleaned.gsub!(%r{<a[^>]*href=["']#{Regexp.escape(TARGET_URL)}["'][^>]*>.*?</a>}mi, PLAIN_TEXT)
    cleaned.gsub!(TARGET_URL, 'www.lwj.co.jp/pc/software/index.html')
    cleaned
  end

  def self.apply_site_config(site)
    social = site.config['social'] || {}
    links = Array(social['links'])
    social['links'] = links.reject { |link| link == TARGET_URL || link == 'http://www.lwj.co.jp/' }
    site.config['social'] = social
  end
end

Jekyll::Hooks.register :site, :after_init do |site|
  ZzzzHttpLinkSanitizer.apply_site_config(site)
end

[:posts, :pages, :documents].each do |scope|
  Jekyll::Hooks.register scope, :pre_render do |doc|
    next unless doc.respond_to?(:content) && doc.content.is_a?(String)
    doc.content = ZzzzHttpLinkSanitizer.sanitize_source(doc.content)
  end
end

Jekyll::Hooks.register :site, :post_write do |site|
  Dir.glob(File.join(site.dest, '**', '*.html')).each do |path|
    next unless File.file?(path)
    original = File.read(path)
    cleaned = ZzzzHttpLinkSanitizer.sanitize_html(original)
    next if cleaned == original
    File.write(path, cleaned)
  end
end
