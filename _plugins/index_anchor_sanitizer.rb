#!/usr/bin/env ruby
# frozen_string_literal: true

module IndexAnchorSanitizer
  LISTING_PATHS = [
    /\/index\.html$/i,
    /\/tags\/.+\/index\.html$/i,
    /\/categories\/.+\/index\.html$/i,
    /\/archives\/index\.html$/i
  ].freeze

  BAD_EMPTY_HREF = /<a([^>]*?)href=(['"])\s*\2([^>]*)>(.*?)<\/a>/mi.freeze
  BAD_NO_HREF_BLOCK = /<a(?![^>]*\bhref=)[^>]*>(.*?)<\/a>/mi.freeze
  BAD_NO_HREF_OPEN = /<a(?![^>]*\bhref=)[^>]*>/mi.freeze
  BAD_CLOSE = /<\/a>/mi.freeze

  def self.listing_page?(path)
    LISTING_PATHS.any? { |pattern| path.match?(pattern) }
  end

  def self.clean_html(text)
    cleaned = text.dup

    # Convert anchors with empty href to plain text.
    cleaned.gsub!(BAD_EMPTY_HREF, '\4')

    # Convert anchors that have no href at all to plain text.
    cleaned.gsub!(BAD_NO_HREF_BLOCK, '\1')
    cleaned.gsub!(BAD_NO_HREF_OPEN, '')

    # Remove stray closing anchor tags that may remain after cleanup.
    cleaned.gsub!(BAD_CLOSE, '')

    cleaned
  end
end

Jekyll::Hooks.register :site, :post_write do |site|
  Dir.glob(File.join(site.dest, '**', '*.html')).each do |path|
    next unless File.file?(path)
    next unless IndexAnchorSanitizer.listing_page?(path)

    original = File.read(path)
    cleaned = IndexAnchorSanitizer.clean_html(original)
    next if cleaned == original

    File.write(path, cleaned)
  end
end
