#!/usr/bin/env ruby
# frozen_string_literal: true

module GithubLinkKiller
  OPEN_PATTERNS = [
    %r{<a[^>]+href=["']https://github\.com/pandaxp28["'][^>]*>}mi,
    %r{<a[^>]+href=["']http://www\.lwj\.co\.jp/pc/software/index\.html["'][^>]*>}mi,
    %r{<a[^>]+href=["']\s*["'][^>]*>}mi
  ].freeze

  def self.clean(text)
    cleaned = text.dup
    OPEN_PATTERNS.each { |pattern| cleaned.gsub!(pattern, '') }
    cleaned
  end
end

Jekyll::Hooks.register :site, :post_write do |site|
  Dir.glob(File.join(site.dest, '**', '*.html')).each do |path|
    next unless File.file?(path)
    original = File.read(path)
    cleaned = GithubLinkKiller.clean(original)
    next if cleaned == original
    File.write(path, cleaned)
  end
end
