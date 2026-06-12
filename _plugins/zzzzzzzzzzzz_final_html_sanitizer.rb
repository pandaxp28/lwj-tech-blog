#!/usr/bin/env ruby
# frozen_string_literal: true

module ZzzzzzzzzzzzFinalHtmlSanitizer
  # Remove any anchor tags that do not have an href attribute.
  BAD_ANCHOR_BLOCK = /<a(?![^>]*\bhref=)[^>]*>(.*?)<\/a>/mi.freeze
  BAD_ANCHOR_OPEN  = /<a(?![^>]*\bhref=)[^>]*>/mi.freeze
  BAD_ANCHOR_CLOSE = /<\/a>/mi.freeze

  def self.clean_html(text)
    cleaned = text.dup
    cleaned.gsub!(BAD_ANCHOR_BLOCK, '\1')
    cleaned.gsub!(BAD_ANCHOR_OPEN, '')
    cleaned.gsub!(BAD_ANCHOR_CLOSE, '')
    cleaned
  end
end

Jekyll::Hooks.register :site, :post_write do |site|
  Dir.glob(File.join(site.dest, '**', '*.html')).each do |path|
    next unless File.file?(path)

    original = File.read(path)
    cleaned = ZzzzzzzzzzzzFinalHtmlSanitizer.clean_html(original)
    next if cleaned == original

    File.write(path, cleaned)
  end
end
