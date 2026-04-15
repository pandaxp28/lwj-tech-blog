#!/usr/bin/env ruby
# frozen_string_literal: true

module ListingPageLinkCleaner
  LISTING_PATHS = [
    /\/index\.html$/i,
    /\/tags\/.+\/index\.html$/i,
    /\/categories\/.+\/index\.html$/i,
    /\/archives\/index\.html$/i
  ].freeze

  TARGETS = [
    %r{<a[^>]+href=["']/lwj-tech-blog/downloads/winmaintenancetool/["'][^>]*>(.*?)</a>}mi,
    %r{<a[^>]+href=["']https://github\.com/pandaxp28/WinMaintenanceTool/releases["'][^>]*>(.*?)</a>}mi
  ].freeze

  def self.listing_page?(path)
    LISTING_PATHS.any? { |pattern| path.match?(pattern) }
  end

  def self.clean_html(text)
    cleaned = text.dup
    TARGETS.each do |pattern|
      cleaned.gsub!(pattern, '\1')
    end
    cleaned
  end
end

Jekyll::Hooks.register :site, :post_write do |site|
  Dir.glob(File.join(site.dest, '**', '*.html')).each do |path|
    next unless File.file?(path)
    next unless ListingPageLinkCleaner.listing_page?(path)

    original = File.read(path)
    cleaned = ListingPageLinkCleaner.clean_html(original)
    next if cleaned == original

    File.write(path, cleaned)
  end
end
